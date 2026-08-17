import SwiftUI
import Contacts
import ContactsUI
import MessageUI

struct ContentView: View {
    var body: some View {
        LandingPage()
    }
}

struct LandingPage: View {
    @StateObject private var contactsVM = ContactViewModel()
    @State private var path = NavigationPath()
    @State private var comingUpScrollID: String?
    /// Widget/person deep link received before birthday contacts finished loading.
    @State private var pendingPersonContactID: String?

    private enum Route: Hashable {
        case browse
        case addMissing
        case edit(String)
        case settings
        case todaysBirthdays
    }

    private let comingUpCardWidth: CGFloat = CompactBdayCard.width
    private let comingUpCardHeight: CGFloat = CompactBdayCard.height
    private let comingUpCardSpacing: CGFloat = 16

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geometry in
                ZStack {
                    // Simple solid background
                    AppTheme.background
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Header - Center Aligned
                        ZStack(alignment: .trailing) {
                            VStack(spacing: 8) {
                                Image(systemName: "birthday.cake.fill")
                                    .font(.system(size: 34))
                                    .foregroundStyle(.cyan)
                                Text("BirthdayPal")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 36, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            
                            Button {
                                path.append(Route.settings)
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white.opacity(0.85))
                                    .padding(10)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.12))
                                    )
                            }
                            .padding(.trailing, 20)
                            .accessibilityLabel("Settings")
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                        
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 28) {
                                // Top 3 Birthdays - Horizontal Scroll
                                if contactsVM.isLoadingBirthdays {
                                    VStack(spacing: 16) {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(1.5)
                                        Text("Loading contacts...")
                                            .foregroundColor(.white.opacity(0.8))
                                            .font(.subheadline)
                                    }
                                    .frame(height: 200)
                                } else if let error = contactsVM.errorMessage {
                                    GlassCard {
                                        VStack(spacing: 16) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .font(.system(size: 50))
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [.orange, .red],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                            Text("Error loading contacts")
                                                .foregroundStyle(.white)
                                                .font(.headline)
                                            Text(error)
                                                .foregroundStyle(.white.opacity(0.7))
                                                .multilineTextAlignment(.center)
                                                .font(.subheadline)
                                            
                                            Button("Retry") {
                                                contactsVM.loadContacts(force: true)
                                            }
                                            .modernButtonStyle()
                                        }
                                        .padding(24)
                                    }
                                    .padding(.horizontal, 20)
                                } else if contactsVM.contactsWithBirthday.isEmpty {
                                    GlassCard {
                                        VStack(spacing: 16) {
                                            Image(systemName: "birthday.cake.fill")
                                                .font(.system(size: 60))
                                                .foregroundStyle(.cyan)
                                            Text("No upcoming birthdays")
                                                .foregroundStyle(.white)
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                            Text("Add birthdays to your contacts to see them here")
                                                .foregroundStyle(.white.opacity(0.7))
                                                .multilineTextAlignment(.center)
                                                .font(.subheadline)
                                        }
                                        .padding(32)
                                    }
                                    .padding(.horizontal, 20)
                                } else {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Label("Coming Up", systemImage: "clock.badge.checkmark")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                            Spacer()
                                            Text("\(contactsVM.upcomingPreview.count) upcoming")
                                                .font(.subheadline)
                                                .foregroundStyle(.white.opacity(0.6))
                                        }
                                        .padding(.horizontal, 24)
                                        
                                        ComingUpCarousel(
                                            contacts: contactsVM.upcomingPreview,
                                            scrollID: $comingUpScrollID,
                                            cardWidth: comingUpCardWidth,
                                            cardHeight: comingUpCardHeight,
                                            spacing: comingUpCardSpacing,
                                            containerWidth: geometry.size.width
                                        ) { contactID in
                                            path.append(Route.edit(contactID))
                                        }
                                    }
                                }
                                
                                // Achievement Card
                                AchievementCardView(rememberedCount: contactsVM.rememberedBirthdaysCount)
                                    .padding(.horizontal, 20)
                                
                                // Today's Birthdays
                                Button {
                                    path.append(Route.todaysBirthdays)
                                } label: {
                                    ActionCard(
                                        icon: "birthday.cake.fill",
                                        title: "Today's Birthdays",
                                        showsTodayIndicator: !contactsVM.todaysBirthdays.isEmpty,
                                        gradientColors: [Color.orange, Color.pink]
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 20)
                                
                                // Browse Birthdays Button
                                Button {
                                    path.append(Route.browse)
                                } label: {
                                    ActionCard(
                                        icon: "calendar",
                                        title: "Browse by Month",
                                        gradientColors: [Color.blue, Color.cyan]
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 20)
                                
                                // Add Missing Birthdays Button
                                Button {
                                    path.append(Route.addMissing)
                                } label: {
                                    ActionCard(
                                        icon: "person.2.fill",
                                        title: "Add missing birthdays",
                                        gradientColors: [Color.purple, Color.blue]
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                            }
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .browse:
                    BrowseBirthdaysView(contactsVM: contactsVM)
                case .addMissing:
                    addMissingView(contactsVM: contactsVM)
                case .edit(let contactID):
                    if let contact = contactsVM.contact(withId: contactID) {
                        EditView(contact: contact, contactsVM: contactsVM)
                    } else {
                        Text("Contact not found")
                            .foregroundStyle(.white)
                    }
                case .settings:
                    SettingsView(contactsVM: contactsVM)
                case .todaysBirthdays:
                    TodaysBirthdaysView(contactsVM: contactsVM) { contactID in
                        path.append(Route.edit(contactID))
                    }
                }
            }
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
            path = NavigationPath()
            path.append(Route.todaysBirthdays)
        case .person(let contactID):
            pendingPersonContactID = contactID
            attemptPendingPersonNavigation()
        }
    }

    /// Opens Send Birthday Message once the matching contact is available (load is async).
    private func attemptPendingPersonNavigation() {
        guard let contactID = pendingPersonContactID else { return }

        if contactsVM.contact(withId: contactID) != nil {
            path = NavigationPath()
            path.append(Route.edit(contactID))
            pendingPersonContactID = nil
            return
        }

        guard !contactsVM.isLoadingBirthdays else { return }

        path = NavigationPath()
        path.append(Route.edit(contactID))
        pendingPersonContactID = nil
    }
}

// MARK: - Today's Birthdays

struct TodaysBirthdaysView: View {
    @ObservedObject var contactsVM: ContactViewModel
    var onSelectContact: (String) -> Void

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Today's Birthdays", systemImage: "birthday.cake.fill")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Text(Date().formattedDate())
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    if contactsVM.isLoadingBirthdays {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if contactsVM.todaysBirthdays.isEmpty {
                        Text("No Birthdays today")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 24)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(contactsVM.todaysBirthdays) { contact in
                                Button {
                                    onSelectContact(contact.id)
                                } label: {
                                    BdayCard(contact: contact)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                }
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Glass Card Component

struct GlassCard<Content: View>: View {
    let content: Content
    let intensity: GlassIntensity
    
    enum GlassIntensity {
        case light, medium, strong
        
        var backgroundOpacity: Double {
            switch self {
            case .light: return 0.4
            case .medium: return 0.5
            case .strong: return 0.6
            }
        }
        
        var borderOpacity: Double {
            switch self {
            case .light: return 0.15
            case .medium: return 0.2
            case .strong: return 0.25
            }
        }
    }
    
    init(intensity: GlassIntensity = .medium, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.intensity = intensity
    }
    
    var body: some View {
        content
            .background(
                ZStack {
                    // Simple dark glass layer
                    RoundedRectangle(cornerRadius: 24)
                        .fill(AppTheme.surface.opacity(intensity.backgroundOpacity))
                    
                    // Subtle border
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(intensity.borderOpacity), lineWidth: 1)
                }
            )
            .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
    }
}

// MARK: - Coming Up Carousel

private struct ComingUpCarousel: View {
    let contacts: [Contact]
    @Binding var scrollID: String?
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let spacing: CGFloat
    let containerWidth: CGFloat
    let onSelect: (String) -> Void

    private var sideInset: CGFloat {
        max((containerWidth - cardWidth) / 2, 24)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(contacts) { contact in
                    Button {
                        onSelect(contact.id)
                    } label: {
                        CompactBdayCard(contact: contact)
                    }
                    .buttonStyle(.plain)
                    .frame(width: cardWidth, height: cardHeight)
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
        .frame(height: 280)
        .onAppear {
            syncScrollID()
        }
        .onChange(of: contacts.map(\.id)) { _, _ in
            syncScrollID()
        }
    }

    private func syncScrollID() {
        guard let firstID = contacts.first?.id else {
            scrollID = nil
            return
        }
        if scrollID == nil || !contacts.contains(where: { $0.id == scrollID }) {
            scrollID = firstID
        }
    }
}

// MARK: - Compact Birthday Card (for horizontal scroll)

struct CompactBdayCard: View {
    static let width: CGFloat = 200
    static let height: CGFloat = 240

    var contact: Contact
    @EnvironmentObject private var settings: AppSettings
    
    var body: some View {
        GlassCard(intensity: .strong) {
            VStack(spacing: 14) {
                ContactPhotoView(name: contact.name, thumbnailData: contact.thumbnailData, size: 72)

                VStack(spacing: 8) {
                    Text(contact.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity)

                    if let display = contact.displayBirthdayDate ?? contact.comparableBirthday {
                        Text(display.formattedMonthDay())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    
                    if settings.showAgeTurning, contact.hasKnownBirthYear, let age = contact.ageTurning {
                        Text("Turning \(age)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    
                    if let days = contact.daysToBirthday {
                        HStack(spacing: 6) {
                            if days == 0 {
                                Image(systemName: "party.popper.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.caption)
                                Text("Today!")
                                    .foregroundStyle(.yellow)
                                    .font(.caption)
                                    .fontWeight(.bold)
                            } else {
                                Image(systemName: "clock.fill")
                                    .foregroundStyle(Color.cyan)
                                    .font(.caption2)
                                Text("\(days) days")
                                    .foregroundStyle(.white.opacity(0.8))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(
                                    AppTheme.background.opacity(0.6)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                }
            }
            .padding(20)
            .frame(width: Self.width, height: Self.height)
        }
    }
}

// MARK: - Action Card

struct ActionCard: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var showsTodayIndicator: Bool = false
    let gradientColors: [Color]
    
    var body: some View {
        GlassCard(intensity: .strong) {
            HStack(spacing: 20) {
                // Simple icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(gradientColors[0].opacity(0.3))
                        .frame(width: 64, height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(title)
                            .foregroundStyle(.white)
                            .font(.headline)
                            .fontWeight(.semibold)
                        if showsTodayIndicator {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                        }
                    }
                    if let subtitle {
                        Text(subtitle)
                            .foregroundStyle(.white.opacity(0.7))
                            .font(.subheadline)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.4))
                    .font(.system(size: 16, weight: .bold))
            }
            .padding(24)
        }
    }
}

// MARK: - Achievement Card

struct AchievementCardView: View {
    let rememberedCount: Int

    var body: some View {
        GlassCard(intensity: .strong) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.yellow)
                            .font(.title2)
                        Text("This Month")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .lastTextBaseline, spacing: 8) {
                            Text("\(rememberedCount)")
                                .font(.system(size: 56, weight: .bold))
                                .foregroundStyle(.cyan)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("sent")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.8))
                                Text("messages")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                }
                .padding(24)

                Spacer()

                Image(systemName: "party.popper.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.yellow)
                    .padding(.trailing, 24)
            }
        }
        .frame(height: 170)
    }
}

// MARK: - Birthday Card

struct BdayCard: View {
    var contact: Contact

    var body: some View {
        GlassCard(intensity: .strong) {
            HStack(alignment: .center, spacing: 16) {
                ContactPhotoView(name: contact.name, thumbnailData: contact.thumbnailData, size: 56)

                Text(contact.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.4))
                    .font(.system(size: 16, weight: .bold))
            }
            .padding(24)
        }
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
            // Simple solid background
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    ContactPhotoView(name: contact.name, thumbnailData: contact.thumbnailData, size: 88)
                    Text("Send Birthday Message")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text(contact.name)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 40)

                // Birthday info card
                if let birthday = contact.birthday {
                    GlassCard {
                        VStack(spacing: 16) {
                            Image(systemName: "birthday.cake.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(colorForBirthMonth(birthday.month))
                            
                            Text(formatBirthday(birthday))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            if settings.showAgeTurning, contact.hasKnownBirthYear, let age = contact.ageTurning {
                                Text("Turning \(age)")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.75))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                // Send button
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
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.blue)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
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
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("Cannot Send Messages").font(.headline).foregroundColor(.white)
                        Text("This device is not configured to send messages.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.7))
                        Button("OK") {
                            messageVM.showComposer = false
                        }
                        .modernButtonStyle()
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
        default: return .cyan
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

            ScrollView {
                LazyVStack(spacing: 16) {
                    VStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 40))
                            .foregroundStyle(.cyan)
                        Text("Add Missing Birthdays")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 20)

                    if contactsVM.isLoadingMissing && contactsVM.contactsWithoutBirthday.isEmpty {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, 40)
                    } else if contactsVM.contactsWithoutBirthday.isEmpty {
                        GlassCard {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 52))
                                    .foregroundStyle(.cyan)
                                Text("No Birthdays Missing!")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                Text("All your contacts have birthdays")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(32)
                        }
                        .padding(.horizontal, 20)
                    } else {
                        addMissingSearchBar(text: $searchText)
                            .padding(.horizontal, 20)

                        if filteredContacts.isEmpty {
                            GlassCard {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.cyan)
                                    Text("No Matches")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                    Text("Try a different name")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .padding(28)
                            }
                            .padding(.horizontal, 20)
                        } else {
                            ForEach(filteredContacts) { contact in
                                addMissingCard(contact: contact) {
                                    editingContactID = ContactSheetTarget(id: contact.id)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .task {
            contactsVM.loadMissingBirthdayContactsIfNeeded()
        }
        .sheet(item: $editingContactID, onDismiss: refreshContactsAfterEditing) { target in
            ContactEditorRepresentable(contactID: target.id) {
                editingContactID = nil
            }
            .ignoresSafeArea()
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

private struct addMissingSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.55))

            TextField("", text: $text, prompt: Text("Search contacts").foregroundColor(.white.opacity(0.45)))
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.surface.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct addMissingCard: View {
    let contact: Contact
    let onAddBirthday: () -> Void

    var body: some View {
        GlassCard(intensity: .strong) {
            HStack(spacing: 12) {
                ContactPhotoView(name: contact.name, thumbnailData: contact.thumbnailData, size: 36)

                Text(contact.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Button(action: onAddBirthday) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.purple)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add birthday")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Contact editor (system Contacts UI)

private final class ContactEditorNavigationController: UINavigationController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        (topViewController as? CNContactViewController)?.setEditing(true, animated: false)
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
        if allowsEditing {
            contactVC.setEditing(true, animated: false)
            return ContactEditorNavigationController(rootViewController: contactVC)
        }
        return UINavigationController(rootViewController: contactVC)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    final class Coordinator: NSObject, CNContactViewControllerDelegate {
        let onComplete: () -> Void

        init(onComplete: @escaping () -> Void) {
            self.onComplete = onComplete
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
            ContentUnavailableView(
                "Contact Not Found",
                systemImage: "person.crop.circle.badge.exclamationmark",
                description: Text("This contact could not be opened.")
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onDismiss)
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
            // Simple solid background
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Browse Birthdays", systemImage: "calendar")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .labelStyle(.titleAndIcon)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Simple tab selector
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = .calendar
                            }
                        }) {
                            Label("Calendar", systemImage: "calendar")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedTab == .calendar ? Color.blue : AppTheme.surface.opacity(0.5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(selectedTab == .calendar ? 0.3 : 0.15), lineWidth: 1)
                                        )
                                )
                        }

                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = .byMonth
                            }
                        }) {
                            Label("By Month", systemImage: "list.bullet")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedTab == .byMonth ? Color.blue : AppTheme.surface.opacity(0.5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(selectedTab == .byMonth ? 0.3 : 0.15), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 20)

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
        .sheet(item: $viewingContactID) { target in
            ContactEditorRepresentable(contactID: target.id, allowsEditing: false) {
                viewingContactID = nil
            }
            .ignoresSafeArea()
        }
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
                Label("Select Month", systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 24)
                
                GlassCard(intensity: .strong) {
                    Picker("Select Month", selection: $selectedMonth) {
                        ForEach(months, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(.white)
                    .padding(20)
                }
                .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("\(selectedMonth) Birthdays (\(monthContacts.count))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
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
            GlassCard(intensity: .strong) {
                HStack(spacing: 16) {
                    birthdayDateBadge(for: contact.displayBirthdayDate ?? contact.comparableBirthday!)

                    ContactPhotoView(name: contact.name, thumbnailData: contact.thumbnailData, size: 44)

                    Text(contact.name)
                        .foregroundColor(.white)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    if settings.showAgeTurning, contact.hasKnownBirthYear, let age = contact.ageTurning {
                        Text("Turning \(age)")
                            .foregroundColor(.white.opacity(0.65))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .padding(20)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }

    private func birthdayDateBadge(for date: Date) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.15, green: 0.2, blue: 0.4).opacity(0.7))
                .frame(width: 56, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                )

            VStack(spacing: 2) {
                Text(date.monthAbbrev())
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                    .fontWeight(.semibold)
                Text(date.day())
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
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
            GlassCard(intensity: .strong) {
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
                    .foregroundColor(.white.opacity(0.7))
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                LazyVStack(spacing: 12) {
                    ForEach(contactsVM.contactsPerDate(date: selectedDate)) { contact in
                        calendarCard(contact: contact)
                    }
                }
                
                if contactsVM.contactsPerDate(date: selectedDate).isEmpty {
                    GlassCard {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.cyan)
                            Text("No birthdays on this date")
                                .foregroundColor(.white.opacity(0.7))
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
            GlassCard(intensity: .strong) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.15, green: 0.2, blue: 0.4).opacity(0.7))
                            .frame(width: 56, height: 56)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                            )

                        VStack(spacing: 2) {
                            Text(selectedDate.monthAbbrev())
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                                .fontWeight(.semibold)
                            Text(selectedDate.day())
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }

                    ContactPhotoView(name: contact.name, thumbnailData: contact.thumbnailData, size: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(contact.name)
                            .foregroundColor(.white)
                            .font(.headline)
                            .fontWeight(.semibold)

                        if settings.showAgeTurning, contact.hasKnownBirthYear, let age = contact.ageTurning {
                            Text("Turning \(age)")
                                .foregroundColor(.white.opacity(0.65))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .padding(20)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }
}

// MARK: - Button Style Extension

extension View {
    func modernButtonStyle() -> some View {
        self
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.blue)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}
