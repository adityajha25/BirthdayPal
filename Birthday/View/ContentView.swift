import SwiftUI
import Contacts
import ContactsUI
import MessageUI

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

// MARK: - Root Tab Navigation

private enum AppTab: Hashable {
    case today
    case browse
    case addMissing
    case settings
}

struct MainTabView: View {
    @StateObject private var contactsVM = ContactViewModel()
    @State private var selectedTab: AppTab = .today
    @State private var todayPath = NavigationPath()
    @State private var browsePath = NavigationPath()
    /// Widget/person deep link received before birthday contacts finished loading.
    @State private var pendingPersonContactID: String?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $todayPath) {
                TodayTabView(contactsVM: contactsVM) { contactID in
                    todayPath.append(contactID)
                }
                .navigationDestination(for: String.self) { contactID in
                    contactEditDestination(contactID)
                }
            }
            .tabItem {
                Label("Today", systemImage: "birthday.cake.fill")
            }
            .tag(AppTab.today)

            NavigationStack(path: $browsePath) {
                BrowseBirthdaysView(contactsVM: contactsVM)
                    .navigationDestination(for: String.self) { contactID in
                        contactEditDestination(contactID)
                    }
            }
            .tabItem {
                Label("Browse", systemImage: "calendar")
            }
            .tag(AppTab.browse)

            NavigationStack {
                addMissingView(contactsVM: contactsVM)
                    .navigationDestination(for: String.self) { contactID in
                        contactEditDestination(contactID)
                    }
            }
            .tabItem {
                Label("Add", systemImage: "person.crop.circle.badge.plus")
            }
            .tag(AppTab.addMissing)

            NavigationStack {
                SettingsView(contactsVM: contactsVM)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(AppTab.settings)
        }
        .environmentObject(AppSettings.shared)
        .task {
            contactsVM.loadContacts()
            applyPendingDeepLinkIfNeeded()
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .onAppear {
            applyPendingDeepLinkIfNeeded()
        }
        .onChange(of: contactsVM.isLoadingBirthdays) { _, _ in
            attemptPendingPersonNavigation()
        }
        .onChange(of: contactsVM.contactsWithBirthday.map(\.id)) { _, _ in
            attemptPendingPersonNavigation()
        }
    }

    @ViewBuilder
    private func contactEditDestination(_ contactID: String) -> some View {
        if let contact = contactsVM.contact(withId: contactID) {
            EditView(contact: contact, contactsVM: contactsVM)
        } else {
            Text("Contact not found")
                .foregroundStyle(AppTheme.text)
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let link = DeepLink.from(url: url) else { return }
        navigate(to: link)
    }

    private func applyPendingDeepLinkIfNeeded() {
        guard let link = DeepLink.consumePending() else { return }
        navigate(to: link)
    }

    private func navigate(to link: DeepLink) {
        switch link {
        case .todaysBirthdays:
            pendingPersonContactID = nil
            selectedTab = .today
            todayPath = NavigationPath()
        case .person(let contactID):
            pendingPersonContactID = contactID
            attemptPendingPersonNavigation()
        }
    }

    /// Opens Send Birthday Message once the matching contact is available (load is async).
    private func attemptPendingPersonNavigation() {
        guard let contactID = pendingPersonContactID else { return }

        selectedTab = .today

        if contactsVM.contact(withId: contactID) != nil {
            todayPath = NavigationPath()
            todayPath.append(contactID)
            pendingPersonContactID = nil
            return
        }

        guard !contactsVM.isLoadingBirthdays else { return }

        todayPath = NavigationPath()
        todayPath.append(contactID)
        pendingPersonContactID = nil
    }
}

// MARK: - Today Tab

struct TodayTabView: View {
    @ObservedObject var contactsVM: ContactViewModel
    var onSelectContact: (String) -> Void
    @State private var scrollID: String?

    private let cardWidth: CGFloat = CompactBdayCard.width
    private let cardSpacing: CGFloat = 16

    private var upcomingBirthdays: [Contact] {
        contactsVM.upcomingPreview
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        if contactsVM.isLoadingBirthdays {
                            loadingState
                        } else if let error = contactsVM.errorMessage {
                            errorState(error)
                        } else if upcomingBirthdays.isEmpty {
                            emptyState
                        } else {
                            birthdayCarousel(containerWidth: geometry.size.width)
                        }

                        if !contactsVM.isLoadingBirthdays, contactsVM.errorMessage == nil {
                            AchievementCardView(rememberedCount: contactsVM.rememberedBirthdaysCount)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .largeNavigationTitle("Today")
        .onAppear { syncScrollID() }
        .onChange(of: upcomingBirthdays.map(\.id)) { _, _ in
            syncScrollID()
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(AppTheme.text)
                .scaleEffect(1.5)
            Text("Loading contacts...")
                .foregroundStyle(AppTheme.text.opacity(0.8))
                .font(.subheadline)
        }
        .frame(height: 280)
    }

    private func errorState(_ error: String) -> some View {
        LiquidGlassCard(padding: 24) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
                    )
                Text("Error loading contacts")
                    .foregroundStyle(AppTheme.text)
                    .font(.headline)
                Text(error)
                    .foregroundStyle(AppTheme.text.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .font(.subheadline)

                Button("Retry") {
                    contactsVM.loadContacts(force: true)
                }
                .primaryGlassButton()
                .tint(.blue)
            }
        }
        .padding(.horizontal, 20)
    }

    private var emptyState: some View {
        LiquidGlassCard(padding: 32) {
            VStack(spacing: 16) {
                Image(systemName: "birthday.cake")
                    .font(.system(size: 60))
                    .foregroundStyle(AppTheme.accent)
                Text("No upcoming birthdays")
                    .foregroundStyle(AppTheme.text)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("Add birthdays in Contacts to see them here")
                    .foregroundStyle(AppTheme.text.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
            }
        }
        .padding(.horizontal, 20)
    }

    private func birthdayCarousel(containerWidth: CGFloat) -> some View {
        TodayBirthdayCarousel(
            contacts: upcomingBirthdays,
            scrollID: $scrollID,
            cardWidth: cardWidth,
            spacing: cardSpacing,
            containerWidth: containerWidth,
            onSelectContact: onSelectContact
        )
        .padding(.top, 8)
    }

    private func syncScrollID() {
        guard !upcomingBirthdays.isEmpty else {
            scrollID = nil
            return
        }
        let initialID = upcomingBirthdays.first(where: { $0.daysToBirthday == 0 })?.id
            ?? upcomingBirthdays.first?.id
        if scrollID == nil || !upcomingBirthdays.contains(where: { $0.id == scrollID }) {
            scrollID = initialID
        }
    }
}

// MARK: - Today Birthday Carousel (CompactBdayCard layout)

private struct TodayBirthdayCarousel: View {
    let contacts: [Contact]
    @Binding var scrollID: String?
    let cardWidth: CGFloat
    let spacing: CGFloat
    let containerWidth: CGFloat
    let onSelectContact: (String) -> Void

    private var sideInset: CGFloat {
        max((containerWidth - cardWidth) / 2, 24)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(contacts) { contact in
                    let isToday = contact.daysToBirthday == 0
                    CompactBdayCard(
                        contact: contact,
                        showsSendMessage: isToday,
                        onSendMessage: isToday ? { onSelectContact(contact.id) } : nil
                    )
                    .frame(width: cardWidth, height: CompactBdayCard.height(showsSendMessage: isToday))
                    .id(contact.id)
                    .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                        content
                            .scaleEffect(1 - (min(abs(phase.value), 1) * 0.12), anchor: .center)
                            .opacity(1 - (min(abs(phase.value), 1) * 0.12))
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrollID)
        .contentMargins(.horizontal, sideInset, for: .scrollContent)
        .frame(height: 320)
    }
}

// MARK: - Compact Birthday Card (original layout + liquid glass)

struct CompactBdayCard: View {
    static let width: CGFloat = 200
    static let baseHeight: CGFloat = 240

    static func height(showsSendMessage: Bool) -> CGFloat {
        showsSendMessage ? 280 : baseHeight
    }

    var contact: Contact
    var showsSendMessage: Bool = false
    var onSendMessage: (() -> Void)? = nil
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(spacing: 14) {
            ContactPhotoView(name: contact.name, thumbnailData: contact.thumbnailData, size: 72)

            VStack(spacing: 8) {
                Text(contact.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity)

                if let display = contact.displayBirthdayDate ?? contact.comparableBirthday {
                    Text(display.formattedMonthDay())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.text.opacity(0.65))
                }

                if settings.showAgeTurning, contact.hasKnownBirthYear, let age = contact.ageTurning {
                    Text("Turning \(age)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.text.opacity(0.75))
                }

                if let days = contact.daysToBirthday {
                    HStack(spacing: 6) {
                        if days == 0 {
                            Image(systemName: "party.popper.fill")
                                .foregroundStyle(AppTheme.celebration)
                                .font(.caption)
                            Text("Today!")
                                .foregroundStyle(AppTheme.celebration)
                                .font(.caption)
                                .fontWeight(.bold)
                        } else {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(AppTheme.accent)
                                .font(.caption2)
                            Text("\(days) days")
                                .foregroundStyle(AppTheme.text.opacity(0.8))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AppTheme.background.opacity(0.6))
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.text.opacity(0.15), lineWidth: 1)
                            )
                    )
                }

                if showsSendMessage, contact.daysToBirthday == 0, let onSendMessage {
                    Button(action: onSendMessage) {
                        Label("Send Message", systemImage: "message.fill")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .primaryGlassButton()
                    .tint(.blue)
                    .padding(.top, 4)
                }
            }
        }
        .padding(20)
        .frame(width: Self.width, height: Self.height(showsSendMessage: showsSendMessage))
        .liquidGlassCard(cornerRadius: LiquidGlass.cardCornerRadius, interactive: true)
    }
}

// MARK: - Achievement Card

struct AchievementCardView: View {
    let rememberedCount: Int

    var body: some View {
        LiquidGlassCard(padding: 24) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(AppTheme.celebration)
                            .font(.title2)
                        Text("This Month")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.text.opacity(0.9))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .lastTextBaseline, spacing: 8) {
                            Text("\(rememberedCount)")
                                .font(.system(size: 56, weight: .bold))
                                .foregroundStyle(AppTheme.accent)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("sent")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppTheme.text.opacity(0.8))
                                Text("messages")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.text.opacity(0.6))
                            }
                        }
                    }
                }
                .padding(24)

                Spacer()

                Image(systemName: "party.popper.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.celebration)
                    .padding(.trailing, 24)
            }
        }
        .frame(height: 170)
    }
}

// MARK: - Edit View

struct EditView: View {
    var contact: Contact
    var contactsVM: ContactViewModel
    @EnvironmentObject private var settings: AppSettings

    @StateObject private var messageVM = BirthdayMessageViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    ContactPhotoView(name: contact.name, thumbnailData: contact.thumbnailData, size: 88)
                    Text(contact.name)
                        .font(.title3)
                        .foregroundColor(AppTheme.text.opacity(0.7))
                }
                .padding(.top, 20)

                // Birthday info card
                if let birthday = contact.birthday {
                    LiquidGlassCard {
                        VStack(spacing: 16) {
                            Image(systemName: "birthday.cake.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(colorForBirthMonth(birthday.month))
                            
                            Text(formatBirthday(birthday))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.text)
                            
                            if settings.showAgeTurning, contact.hasKnownBirthYear, let age = contact.ageTurning {
                                Text("Turning \(age)")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.text.opacity(0.75))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                Button(action: {
                    let cnContact = convertToCNContact(contact)
                    messageVM.startBirthdayFlow(with: [cnContact], thumbnailData: [contact.thumbnailData])
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "message.fill")
                            .font(.title3)
                        Text("Send Message")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
                .primaryGlassButton()
                .tint(.blue)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .largeNavigationTitle("Send Birthday Message")
        .sheet(isPresented: $messageVM.showTemplatePicker) {
            MessageTemplatePickerView(messageVM: messageVM)
        }
        .fullScreenCover(isPresented: $messageVM.showComposer) {
            if MFMessageComposeViewController.canSendText() {
                MessageComposerView(
                    recipients: messageVM.composerRecipients,
                    body: messageVM.composerBody,
                    onFinish: { result in
                        if result == .sent {
                            NotificationCenter.default.post(name: .birthdayMessageSent, object: nil)
                        }
                        messageVM.composerFinished()
                        dismiss()
                    }
                )
                .ignoresSafeArea()
            } else {
                ZStack {
                    AppTheme.background.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("Cannot Send Messages").font(.headline).foregroundColor(AppTheme.text)
                        Text("This device is not configured to send messages.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(AppTheme.text.opacity(0.7))
                        Button("OK") {
                            messageVM.showComposer = false
                        }
                        .primaryGlassButton()
                        .tint(.blue)
                    }
                    .padding()
                }
            }
        }
        .alert("Error", isPresented: .constant(messageVM.lastError != nil)) {
            Button("OK") { messageVM.lastError = nil }
        } message: {
            if let error = messageVM.lastError { Text(error) }
        }
    }

    private func formatBirthday(_ birthday: DateComponents) -> String {
        guard let month = birthday.month, let day = birthday.day else {
            return "Unknown"
        }
        let monthName = Calendar.current.monthSymbols[month - 1]
        if let year = Contact.validBirthYear(birthday.year) {
            return "\(monthName) \(day), \(year)"
        }
        // No reliable year from Contacts — never show a placeholder like ", 1"
        return "\(monthName) \(day)"
    }

    private func colorForBirthMonth(_ month: Int?) -> Color {
        switch month {
        case 1:  return Color(red: 0.55, green: 0.75, blue: 0.95) // January — ice blue
        case 2:  return Color(red: 0.85, green: 0.55, blue: 0.75) // February — blush
        case 3:  return Color(red: 0.45, green: 0.80, blue: 0.55) // March — spring green
        case 4:  return Color(red: 0.95, green: 0.70, blue: 0.85) // April — soft pink
        case 5:  return Color(red: 0.40, green: 0.85, blue: 0.75) // May — mint
        case 6:  return Color(red: 0.95, green: 0.80, blue: 0.35) // June — sunflower
        case 7:  return Color(red: 1.00, green: 0.55, blue: 0.35) // July — citrus
        case 8:  return Color(red: 0.95, green: 0.45, blue: 0.40) // August — coral
        case 9:  return Color(red: 0.85, green: 0.60, blue: 0.30) // September — amber
        case 10: return Color(red: 0.90, green: 0.45, blue: 0.25) // October — pumpkin
        case 11: return Color(red: 0.70, green: 0.50, blue: 0.85) // November — plum
        case 12: return Color(red: 0.40, green: 0.70, blue: 0.90) // December — winter blue
        default: return AppTheme.accent
        }
    }

    private func convertToCNContact(_ contact: Contact) -> CNContact {
        let cn = CNMutableContact()
        let parts = contact.name.split(separator: " ")
        if let first = parts.first { cn.givenName = String(first) }
        if parts.count > 1 { cn.familyName = parts.dropFirst().joined(separator: " ") }
        if let phone = contact.phoneNumber {
            cn.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain,
                                              value: CNPhoneNumber(stringValue: phone))]
        }
        if let b = contact.birthday { cn.birthday = b }
        return cn.copy() as! CNContact
    }
}

// MARK: - Add Missing View

private struct ContactSheetTarget: Identifiable {
    let id: String
}

struct addMissingView: View {
    @ObservedObject var contactsVM: ContactViewModel
    @State private var editingContactID: ContactSheetTarget?
    @State private var searchText = ""
    @Environment(\.scenePhase) private var scenePhase

    private var filteredContacts: [Contact] {
        let contacts = contactsVM.contactsWithoutBirthday
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return contacts }
        return contacts.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            Group {
                if contactsVM.isLoadingMissing && contactsVM.contactsWithoutBirthday.isEmpty {
                    ProgressView()
                        .tint(AppTheme.text)
                } else if contactsVM.contactsWithoutBirthday.isEmpty {
                    ScrollView {
                        LiquidGlassCard(padding: 32) {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 52))
                                    .foregroundStyle(AppTheme.accent)
                                Text("No Birthdays Missing!")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppTheme.text)
                                Text("All your contacts have birthdays")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.text.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredContacts) { contact in
                                addMissingCard(contact: contact) {
                                    editingContactID = ContactSheetTarget(id: contact.id)
                                }
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .largeNavigationTitle("Add Missing Birthdays")
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search contacts"
        )
        .task {
            contactsVM.loadMissingBirthdayContactsIfNeeded()
        }
        .sheet(item: $editingContactID, onDismiss: refreshContactsAfterEditing) { target in
            ContactSheetView(contactID: target.id, allowsEditing: true) {
                editingContactID = nil
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                refreshContactsAfterEditing()
            }
        }
    }

    private func refreshContactsAfterEditing() {
        contactsVM.loadContacts(force: true)
        contactsVM.loadMissingBirthdayContactsIfNeeded(force: true)
    }
}

struct addMissingCard: View {
    let contact: Contact
    let onAddBirthday: () -> Void

    var body: some View {
        ContactGlassRow(padding: 16) {
            HStack(spacing: 12) {
                ContactPhotoView(name: contact.name, thumbnailData: contact.thumbnailData, size: 36)

                Text(contact.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Button(action: onAddBirthday) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .glassCircleButton()
                .accessibilityLabel("Add birthday")
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Contact editor (system Contacts UI)

/// Hosts CNContactViewController directly. Dismiss comes from the system nav bar item
/// installed by `ContactSheetNavigationController`, plus swipe-to-dismiss.
private struct ContactSheetView: View {
    let contactID: String
    var allowsEditing = true
    var onComplete: () -> Void

    var body: some View {
        ContactEditorRepresentable(
            contactID: contactID,
            allowsEditing: allowsEditing,
            onComplete: onComplete
        )
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(false)
    }
}

/// CNContactViewController replaces navigation items after load; re-apply dismiss
/// on every appearance so Done/Cancel stays visible in the system nav bar too.
private final class ContactSheetNavigationController: UINavigationController {
    var onDismiss: (() -> Void)?
    var dismissSystemItem: UIBarButtonItem.SystemItem = .done
    var startsInEditMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isHidden = false
        isNavigationBarHidden = false
        installDismissButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarHidden(false, animated: false)
        installDismissButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNavigationBarHidden(false, animated: false)
        if startsInEditMode {
            (topViewController as? CNContactViewController)?.setEditing(true, animated: false)
        }
        installDismissButton()
        DispatchQueue.main.async { [weak self] in
            self?.installDismissButton()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.installDismissButton()
        }
    }

    private func installDismissButton() {
        guard let contactVC = viewControllers.first else { return }
        let item = UIBarButtonItem(
            barButtonSystemItem: dismissSystemItem,
            target: self,
            action: #selector(dismissTapped)
        )
        contactVC.navigationItem.leftBarButtonItem = item
        contactVC.navigationItem.hidesBackButton = true
    }

    @objc private func dismissTapped() {
        onDismiss?()
    }
}

private struct ContactEditorRepresentable: UIViewControllerRepresentable {
    let contactID: String
    var allowsEditing = true
    var onComplete: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let store = CNContactStore()
        let keys: [CNKeyDescriptor] = [CNContactViewController.descriptorForRequiredKeys()]

        guard let contact = try? store.unifiedContact(withIdentifier: contactID, keysToFetch: keys) else {
            return UIHostingController(rootView: ContactEditorErrorView(onDismiss: onComplete))
        }

        let contactVC = CNContactViewController(for: contact)
        contactVC.allowsEditing = allowsEditing
        contactVC.allowsActions = true
        contactVC.contactStore = store
        contactVC.delegate = context.coordinator

        // Set the dismiss item on the contact VC itself before wrapping — viewDidLoad
        // of a wrapping nav is too early; ContactsUI overwrites items as it appears.
        let dismissItem = UIBarButtonItem(
            barButtonSystemItem: allowsEditing ? .cancel : .done,
            target: context.coordinator,
            action: #selector(Coordinator.dismissTapped)
        )
        contactVC.navigationItem.leftBarButtonItem = dismissItem
        contactVC.navigationItem.hidesBackButton = true

        if allowsEditing {
            contactVC.setEditing(true, animated: false)
        }

        let nav = ContactSheetNavigationController(rootViewController: contactVC)
        nav.onDismiss = onComplete
        nav.dismissSystemItem = allowsEditing ? .cancel : .done
        nav.startsInEditMode = allowsEditing
        return nav
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    final class Coordinator: NSObject, CNContactViewControllerDelegate {
        let onComplete: () -> Void

        init(onComplete: @escaping () -> Void) {
            self.onComplete = onComplete
        }

        @objc func dismissTapped() {
            onComplete()
        }

        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            onComplete()
        }
    }
}

private struct ContactEditorErrorView: View {
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ContentUnavailableView(
                    "Contact Not Found",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text("This contact could not be opened.")
                )
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onDismiss)
                        .secondaryGlassButton()
                }
            }
        }
    }
}

// MARK: - Browse + Calendar

struct BrowseBirthdaysView: View {
    @State private var selectedMonth = "January"
    @State private var selectedTab: ViewMode = .calendar
    @State private var selectedDate = Date()
    @State private var viewingContactID: ContactSheetTarget?
    var contactsVM: ContactViewModel

    enum ViewMode { case byMonth, calendar }

    let months = [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ]

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 12) {
                        browseModeButton(
                            title: "Calendar",
                            isSelected: selectedTab == .calendar
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = .calendar
                            }
                        }

                        browseModeButton(
                            title: "By Month",
                            isSelected: selectedTab == .byMonth
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = .byMonth
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    if selectedTab == .byMonth {
                        ByMonthView(
                            selectedMonth: $selectedMonth,
                            months: months,
                            contactsVM: contactsVM,
                            onContactTap: { viewingContactID = ContactSheetTarget(id: $0) }
                        )
                    } else {
                        CalendarView(
                            selectedDate: $selectedDate,
                            contactsVM: contactsVM,
                            onContactTap: { viewingContactID = ContactSheetTarget(id: $0) }
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 32)
            }
        }
        .largeNavigationTitle("Browse")
        .sheet(item: $viewingContactID) { target in
            ContactSheetView(contactID: target.id, allowsEditing: false) {
                viewingContactID = nil
            }
        }
    }

    @ViewBuilder
    private func browseModeButton(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .browseGlassButtonStyle(isProminent: isSelected)
        .if(isSelected, transform: { $0.tint(.blue) }, else: { $0 })
    }
}

struct ByMonthView: View {
    @Binding var selectedMonth: String
    let months: [String]
    var contactsVM: ContactViewModel
    var onContactTap: (String) -> Void
    @EnvironmentObject private var settings: AppSettings

    private var monthContacts: [Contact] {
        contactsVM.contactsPerMonth(monthName: selectedMonth)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Month")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.text.opacity(0.7))
                    .padding(.horizontal, 24)

                ContactGlassRow {
                    Picker("Select Month", selection: $selectedMonth) {
                        ForEach(months, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.text)
                }
                .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("\(selectedMonth) Birthdays (\(monthContacts.count))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.text)
                    .padding(.horizontal, 24)

                LazyVStack(spacing: 16) {
                    ForEach(monthContacts) { contact in
                        monthCard(contact: contact)
                    }
                }
            }
        }
    }

    func monthCard(contact: Contact) -> some View {
        Button {
            onContactTap(contact.id)
        } label: {
            ContactGlassRow {
                HStack(spacing: 16) {
                    birthdayDateBadge(for: contact.displayBirthdayDate ?? contact.comparableBirthday!)

                    ContactPhotoView(name: contact.name, thumbnailData: contact.thumbnailData, size: 44)

                    Text(contact.name)
                        .foregroundColor(AppTheme.text)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    if settings.showAgeTurning, contact.hasKnownBirthYear, let age = contact.ageTurning {
                        Text("Turning \(age)")
                            .foregroundColor(AppTheme.text.opacity(0.65))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.text.opacity(0.4))
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }

    private func birthdayDateBadge(for date: Date) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.badgeFill.opacity(0.7))
                .frame(width: 56, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.text.opacity(0.25), lineWidth: 1.5)
                )

            VStack(spacing: 2) {
                Text(date.monthAbbrev())
                    .font(.caption2)
                    .foregroundColor(AppTheme.text.opacity(0.8))
                    .fontWeight(.semibold)
                Text(date.day())
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.text)
            }
        }
    }
}

struct CalendarView: View {
    @Binding var selectedDate: Date
    var contactsVM: ContactViewModel
    var onContactTap: (String) -> Void
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(spacing: 20) {
            LiquidGlassCard(padding: 8) {
                BirthdayCalendarRepresentable(
                    selectedDate: $selectedDate,
                    contactsVM: contactsVM
                )
                .frame(maxWidth: .infinity)
                .frame(height: 360)
                .clipped()
                .padding(8)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 12) {
                Text("Selected: \(selectedDate.formattedDate())")
                    .foregroundColor(AppTheme.text.opacity(0.7))
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                LazyVStack(spacing: 12) {
                    ForEach(contactsVM.contactsPerDate(date: selectedDate)) { contact in
                        calendarCard(contact: contact)
                    }
                }
                
                if contactsVM.contactsPerDate(date: selectedDate).isEmpty {
                    LiquidGlassCard(padding: 24) {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 40))
                                .foregroundStyle(AppTheme.accent)
                            Text("No birthdays on this date")
                                .foregroundColor(AppTheme.text.opacity(0.7))
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    func calendarCard(contact: Contact) -> some View {
        Button {
            onContactTap(contact.id)
        } label: {
            ContactGlassRow {
                HStack(spacing: 16) {
                    birthdayDateBadge(for: selectedDate)

                    ContactPhotoView(name: contact.name, thumbnailData: contact.thumbnailData, size: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(contact.name)
                            .foregroundColor(AppTheme.text)
                            .font(.headline)
                            .fontWeight(.semibold)

                        if settings.showAgeTurning, contact.hasKnownBirthYear, let age = contact.ageTurning {
                            Text("Turning \(age)")
                                .foregroundColor(AppTheme.text.opacity(0.65))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.text.opacity(0.4))
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }

    private func birthdayDateBadge(for date: Date) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.badgeFill.opacity(0.7))
                .frame(width: 56, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.text.opacity(0.25), lineWidth: 1.5)
                )

            VStack(spacing: 2) {
                Text(date.monthAbbrev())
                    .font(.caption2)
                    .foregroundColor(AppTheme.text.opacity(0.8))
                    .fontWeight(.semibold)
                Text(date.day())
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.text)
            }
        }
    }
}

// MARK: - View helpers

private extension View {
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        transform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            transform(self)
        } else {
            elseTransform(self)
        }
    }
}
