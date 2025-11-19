import SwiftUI
import Contacts
import MessageUI

struct ContentView: View {
    var body: some View {
        if #available(iOS 17.0, *) {
            LandingPage()
        } else {
            Text("Requires iOS 17 or later")
        }
    }
}

@available(iOS 17.0, *)
struct LandingPage: View {
    @StateObject private var contactsVM = ContactViewModel()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Simple solid background
                    Color(red: 0.08, green: 0.12, blue: 0.28)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Header - Center Aligned
                        VStack(spacing: 8) {
                            Text("BirthdayPal")
                                .foregroundStyle(.white)
                                .font(.system(size: 36, weight: .bold))
                            
                            Text("Never miss a special day")
                                .foregroundStyle(.white.opacity(0.7))
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                        
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 28) {
                                // Top 3 Birthdays - Horizontal Scroll
                                if contactsVM.isLoading {
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
                                                contactsVM.loadContacts()
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
                                            Text("Coming Up")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                            Spacer()
                                            Text("\(min(contactsVM.contactsWithBirthday.count, 3)) of \(contactsVM.contactsWithBirthday.count)")
                                                .font(.subheadline)
                                                .foregroundStyle(.white.opacity(0.6))
                                        }
                                        .padding(.horizontal, 24)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(Array(contactsVM.contactsWithBirthday.prefix(3))) { contact in
                                                    NavigationLink(
                                                        destination: EditView(
                                                            contact: contact,
                                                            contactsVM: contactsVM
                                                        )
                                                    ) {
                                                        CompactBdayCard(contact: contact)
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                            }
                                            .padding(.horizontal, 24)
                                        }
                                    }
                                }
                                
                                // Achievement Card
                                AchievementCardView(rememberedCount: contactsVM.rememberedBirthdaysCount)
                                    .padding(.horizontal, 20)
                                
                                // Browse Birthdays Button
                                NavigationLink(destination: BrowseBirthdaysView(contactsVM: contactsVM)) {
                                    ActionCard(
                                        icon: "calendar",
                                        title: "Browse by Month",
                                        subtitle: "View all birthdays",
                                        gradientColors: [Color.blue, Color.cyan]
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 20)
                                
                                // Add Missing Birthdays Button
                                NavigationLink(destination: addMissingView(contactsVM: contactsVM)) {
                                    ActionCard(
                                        icon: "person.2.fill",
                                        title: "Add missing birthdays",
                                        subtitle: "Complete your contacts",
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
        }
        .onAppear {
            contactsVM.loadContacts()
            BirthdayNotificationManager.shared.requestAuthorizationIfNeeded()
        }
        .onReceive(contactsVM.$contacts) { _ in
            // Notification scheduling
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
                        .fill(Color(red: 0.12, green: 0.16, blue: 0.35).opacity(intensity.backgroundOpacity))
                    
                    // Subtle border
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(intensity.borderOpacity), lineWidth: 1)
                }
            )
            .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
    }
}

// MARK: - Compact Birthday Card (for horizontal scroll)

struct CompactBdayCard: View {
    var contact: Contact
    
    var body: some View {
        GlassCard(intensity: .strong) {
            VStack(spacing: 16) {
                // Date badge with simple glass effect
                ZStack {
                    // Simple dark badge
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 0.15, green: 0.2, blue: 0.4).opacity(0.7))
                        .frame(width: 90, height: 90)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 4) {
                        let parts = contact.comparableBirthday!.formattedMonthDay().split(separator: " ")
                        Text(String(parts[0]))
                            .foregroundStyle(.white.opacity(0.9))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .textCase(.uppercase)
                        Text(String(parts[1]))
                            .foregroundStyle(.white)
                            .font(.system(size: 32, weight: .bold))
                    }
                }
                
                VStack(spacing: 8) {
                    Text(contact.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
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
                                    Color(red: 0.08, green: 0.12, blue: 0.28).opacity(0.6)
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
            .frame(width: 200)
        }
    }
}

// MARK: - Action Card

struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
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
                    Text(title)
                        .foregroundStyle(.white)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(subtitle)
                        .foregroundStyle(.white.opacity(0.7))
                        .font(.subheadline)
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
                        Text("Birthdays Remembered")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))

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

                // Decorative element
                Text("🎉")
                    .font(.system(size: 50))
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
            HStack(alignment: .center, spacing: 20) {
                // Date badge
                ZStack {
                    // Simple dark container
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 0.15, green: 0.2, blue: 0.4).opacity(0.7))
                        .frame(width: 80, height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                        )
                    
                    VStack(spacing: 2) {
                        let parts = contact.comparableBirthday!.formattedMonthDay().split(separator: " ")
                        Text(String(parts[0]))
                            .foregroundStyle(.white.opacity(0.9))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .textCase(.uppercase)
                        Text(String(parts[1]))
                            .foregroundStyle(.white)
                            .font(.system(size: 28, weight: .bold))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(contact.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    if let days = contact.daysToBirthday {
                        HStack(spacing: 8) {
                            if days == 0 {
                                Image(systemName: "party.popper.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.body)
                                Text("Birthday Today!")
                                    .foregroundStyle(.yellow)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            } else {
                                Image(systemName: "clock.fill")
                                    .foregroundStyle(Color.cyan)
                                    .font(.caption)
                                Text("In \(days) days")
                                    .foregroundStyle(.white.opacity(0.8))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(
                                    Color(red: 0.08, green: 0.12, blue: 0.28).opacity(0.6)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
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

// MARK: - Edit View
@available(iOS 17.0, *)
struct EditView: View {
    var contact: Contact
    var contactsVM: ContactViewModel

    @StateObject private var messageVM = BirthdayMessageViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Simple solid background
            Color(red: 0.08, green: 0.12, blue: 0.28)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
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
                            Text("🎂")
                                .font(.system(size: 60))
                            
                            Text(formatBirthday(birthday))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
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
                    messageVM.startBirthdayFlow(with: [cnContact])
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
            if #available(iOS 18.0, *) {
                MessageTemplatePickerView(messageVM: messageVM)
            } else {
                Text("Template picker requires iOS 18 or later")
                    .foregroundColor(.white)
            }
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
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        if let date = Calendar.current.date(from: birthday) {
            return formatter.string(from: date)
        }
        if let month = birthday.month, let day = birthday.day {
            let monthName = Calendar.current.monthSymbols[month - 1]
            return "\(monthName) \(day)"
        }
        return "Unknown"
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

struct addMissingView: View {
    @ObservedObject var contactsVM: ContactViewModel
    
    var body: some View {
        ZStack {
            // Simple solid background
            Color(red: 0.08, green: 0.12, blue: 0.28)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("Add Missing Birthdays")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.top, 20)
                    
                    ForEach($contactsVM.contacts) { $contact in
                        if contact.birthday == nil {
                            addMissingCard(contact: $contact)
                        }
                    }
                    
                    if contactsVM.contactsWithoutBirthday.count == 0 {
                        GlassCard {
                            VStack(spacing: 16) {
                                Text("🎉")
                                    .font(.system(size: 60))
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
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
}

struct addMissingCard: View {
    @Binding var contact: Contact
    @State private var showSheet = false
    
    var phoneNumber: String {
        contact.phoneNumber ?? "No phone number"
    }
    
    var body: some View {
        GlassCard(intensity: .strong) {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(contact.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text(phoneNumber)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Button(action: { showSheet = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Add Birthday")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .sheet(isPresented: $showSheet) {
                        addMissingCalendar(contact: $contact)
                    }
                }
                Spacer()
            }
            .padding(24)
        }
        .padding(.horizontal, 20)
    }
}

struct addMissingCalendar: View {
    @Binding var contact: Contact
    @State private var selectedDate = Date()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Simple solid background
            Color(red: 0.08, green: 0.12, blue: 0.28)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Add Missing Birthday")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("Select a date for \(contact.name)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top, 40)
                
                GlassCard(intensity: .strong) {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .colorScheme(.dark)
                        .accentColor(.cyan)
                        .padding(20)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: {
                    let components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
                    contact.birthday = components
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("Save Birthday")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.green)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Browse + Calendar

@available(iOS 17.0, *)
struct BrowseBirthdaysView: View {
    @State private var selectedMonth = "January"
    @State private var selectedTab: ViewMode = .byMonth
    @State private var selectedDate = Date()
    var contactsVM: ContactViewModel

    enum ViewMode { case byMonth, calendar }

    let months = [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ]

    var body: some View {
        ZStack {
            // Simple solid background
            Color(red: 0.08, green: 0.12, blue: 0.28)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Browse Birthdays")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Text("View by month or calendar")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Simple tab selector
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = .byMonth
                            }
                        }) {
                            Text("By Month")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedTab == .byMonth ? Color.blue : Color(red: 0.12, green: 0.16, blue: 0.35).opacity(0.5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(selectedTab == .byMonth ? 0.3 : 0.15), lineWidth: 1)
                                        )
                                )
                        }
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = .calendar
                            }
                        }) {
                            Text("Calendar")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedTab == .calendar ? Color.blue : Color(red: 0.12, green: 0.16, blue: 0.35).opacity(0.5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(selectedTab == .calendar ? 0.3 : 0.15), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 24)

                    if selectedTab == .byMonth {
                        ByMonthView(selectedMonth: $selectedMonth, months: months, contactsVM: contactsVM)
                    } else {
                        CalendarView(selectedDate: $selectedDate, contactsVM: contactsVM)
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
}

@available(iOS 17.0, *)
struct ByMonthView: View {
    @Binding var selectedMonth: String
    let months: [String]
    var contactsVM: ContactViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Month")
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
                Text("\(selectedMonth) Birthdays")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)

                ForEach(contactsVM.contactsPerMonth(monthName: selectedMonth)) { contact in
                    monthCard(contact: contact)
                }
            }
        }
    }

    func monthCard(contact: Contact) -> some View {
        GlassCard(intensity: .strong) {
            HStack(spacing: 20) {
                ZStack {
                    // Simple dark badge
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.15, green: 0.2, blue: 0.4).opacity(0.7))
                        .frame(width: 65, height: 65)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                        )
                    
                    VStack(spacing: 2) {
                        Text(contact.comparableBirthday!.monthAbbrev())
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                            .fontWeight(.semibold)
                        Text(contact.comparableBirthday!.day())
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                Text(contact.name)
                    .foregroundColor(.white)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.4))
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .padding(20)
        }
        .padding(.horizontal, 24)
    }
}

@available(iOS 17.0, *)
struct CalendarView: View {
    @Binding var selectedDate: Date
    var contactsVM: ContactViewModel

    var body: some View {
        VStack(spacing: 20) {
            GlassCard(intensity: .strong) {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .colorScheme(.dark)
                    .accentColor(.cyan)
                    .padding(20)
            }
            .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 12) {
                Text("Selected: \(selectedDate.formattedDate())")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.subheadline)
                    .padding(.horizontal, 24)

                ForEach(contactsVM.contactsPerDate(date: selectedDate)) { contact in
                    calendarCard(name: contact.name)
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
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    func calendarCard(name: String) -> some View {
        GlassCard(intensity: .strong) {
            HStack(spacing: 20) {
                ZStack {
                    // Simple dark badge
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.15, green: 0.2, blue: 0.4).opacity(0.7))
                        .frame(width: 65, height: 65)
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
                
                Text(name)
                    .foregroundColor(.white)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.4))
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .padding(20)
        }
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
