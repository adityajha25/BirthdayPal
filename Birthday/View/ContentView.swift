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
                VStack {
                    // Header
                    HStack {
                        Text("BirthdayPal")
                            .foregroundStyle(.white)
                            .font(.title)
                        Spacer()
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("Never miss a special day")
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("Upcoming")
                            .foregroundStyle(.white)
                            .font(.title3)
                        Spacer()
                        Text("\(contactsVM.birthdaysThisMonthCount) this month")
                            .foregroundStyle(.white)
                            .font(.title3)
                    }
                    .padding()

                    // Main content
                    if contactsVM.isLoading {
                        Spacer()
                        ProgressView("Loading contacts...")
                            .foregroundColor(.white)
                            .tint(.white)
                        Spacer()
                    } else if let error = contactsVM.errorMessage {
                        Spacer()
                        VStack(spacing: 16) {
                            Text("Error loading contacts")
                                .foregroundStyle(.white)
                                .font(.title3)
                            Text(error)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button("Retry") {
                                contactsVM.loadContacts()
                            }
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                        }
                        Spacer()
                    } else if contactsVM.contactsWithBirthday.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "birthday.cake")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No upcoming birthdays")
                                .foregroundStyle(.white)
                                .font(.title3)
                            Text("Add birthdays to your contacts to see them here")
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            ForEach(contactsVM.contactsWithBirthday) { contact in
                                NavigationLink(
                                    destination: EditView(
                                        contact: contact,
                                        contactsVM: contactsVM        // 🚩 pass VM down for counter
                                    )
                                ) {
                                    BdayCard(
                                        contact: contact,
                                        screenwidth: geometry.size.width,
                                        screenheight: geometry.size.height
                                    )
                                }
                            }
                        }
                    }
                    AchievementCardView(rememberedCount: contactsVM.rememberedBirthdaysCount)
                    NavigationLink(destination: BrowseBirthdaysView(contactsVM: contactsVM)) {
                        browseMonth(
                            screenwidth: geometry.size.width,
                            screenheight: geometry.size.height
                        )
                    }
                    NavigationLink(destination: addMissingView(contactsVM: contactsVM) ) {
                        addMissing(screenwidth: geometry.size.width, screenheight: geometry.size.height)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color.black)
            }
        }
        .onAppear {
            // load contacts + ask for notification permission
            contactsVM.loadContacts()
            BirthdayNotificationManager.shared.requestAuthorizationIfNeeded()
            // first schedule (midnight alerts for birthdays)
            BirthdayNotificationManager.shared.scheduleAnnualMidnight(for: contactsVM.contacts)
        }
        // reschedule whenever contacts list changes
        .onReceive(contactsVM.$contacts) { _ in
            BirthdayNotificationManager.shared.scheduleAnnualMidnight(for: contactsVM.contacts)
        }
    }
}

// MARK: - Browse Month Card

struct browseMonth: View {
    var screenwidth: CGFloat
    var screenheight: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                .frame(height: screenheight * 0.1)

            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray)
                        .frame(width: screenwidth * 0.1, height: screenwidth * 0.1)

                    Image(systemName: "calendar")
                        .resizable()
                        .frame(width: screenwidth * 0.05, height: screenheight * 0.025)
                        .foregroundColor(.black)
                }
                .padding()

                VStack(alignment: .leading) {
                    Text("Browse by Month")
                        .foregroundStyle(.white)
                    Text("View all birthdays")
                        .foregroundStyle(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .padding(.horizontal)
    }
}

struct addMissing: View {
    var screenwidth: CGFloat
    var screenheight: CGFloat
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                .frame(height: screenheight * 0.1)
            
            HStack{
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray)
                        .frame(width: screenwidth * 0.1, height: screenwidth * 0.1)

                    Image(systemName: "person.2.fill")
                        .resizable()
                        .frame(width: screenwidth * 0.05, height: screenheight * 0.025)
                        .foregroundColor(.black)
                }.padding()
                VStack(alignment: .leading) {
                    Text("Add missing birthdays")
                        .foregroundStyle(.white)
                    Text("Complete your contacts")
                        .foregroundStyle(.gray)
                }
                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .padding()
            }
        }.padding(.horizontal)
    }
}

// MARK: - Achievement Card

struct AchievementCardView: View {
    let rememberedCount: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                .shadow(radius: 5)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                        Text("2024 Achievement")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Text("You've remembered")
                        .font(.headline)
                        .foregroundColor(.gray)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(rememberedCount)")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                        Text("birthdays")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                .padding(16)

                Spacer()

                Text("🎂")
                    .font(.system(size: 50))
                    .padding(.trailing, 16)
                    .padding(.top, 16)
            }
        }
        .frame(height: 150)
        .padding()
    }
}

// MARK: - Birthday Card

struct BdayCard: View {
    var contact: Contact
    var screenwidth: CGFloat
    var screenheight: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                .frame(height: screenheight * 0.16)

            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.clear)
                        .stroke(Color.white)
                        .frame(width: screenwidth * 0.125, height: screenwidth * 0.125)

                    VStack {
                        let parts = contact.comparableBirthday!.formattedMonthDay().split(separator: " ")
                        Text(String(parts[0]))
                            .foregroundStyle(.white)
                            .padding(.top, 1)
                        Text(String(parts[1]))
                            .foregroundStyle(.white)
                            .padding(.bottom, 1)
                    }
                }
                .frame(width: screenwidth * 0.15, height: screenwidth * 0.15)
                .padding(.trailing, 4)

                VStack(alignment: .leading) {
                    Text(contact.name)
                        .bold()
                        .font(.system(size: 25))
                        .foregroundStyle(.white)
                    if let days = contact.daysToBirthday {
                        if days != 0 {
                            Text("In \(days) days")
                                .foregroundStyle(.white)
                        } else {
                            Text("Birthday Today 🎂 🎁 🎉")
                                .foregroundStyle(.white)
                                .fontWeight(.bold)
                        }
                    }
                }

                Spacer()
            }
            .padding(10)
        }
        .padding(.horizontal)
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
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Send Birthday Message")
                    .font(.title)
                    .foregroundColor(.white)

                Text(contact.name)
                    .font(.headline)
                    .foregroundColor(.gray)

                if let birthday = contact.birthday {
                    VStack(spacing: 8) {
                        Text("🎂").font(.system(size: 40))
                        Text(formatBirthday(birthday))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color(white: 0.15))
                    .cornerRadius(12)
                }

                Spacer()

                Button(action: {
                    let cnContact = convertToCNContact(contact)
                    messageVM.startBirthdayFlow(with: [cnContact])
                }) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Send Message")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
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
                        // ✅ Only count when the user actually sends the message
                        if result == .sent {
                            NotificationCenter.default.post(name: .birthdayMessageSent, object: nil)
                        }
                        messageVM.composerFinished()
                        dismiss()
                    }
                )
                .ignoresSafeArea()
            } else {
                VStack(spacing: 20) {
                    Text("Cannot Send Messages").font(.headline)
                    Text("This device is not configured to send messages.")
                        .multilineTextAlignment(.center)
                    Button("OK") {
                        messageVM.showComposer = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
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

struct addMissingView: View {
    @ObservedObject var contactsVM: ContactViewModel
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Add Mising Birthdays").bold().font(.system(size: 25)).foregroundStyle(.white)
                ForEach($contactsVM.contacts){ $contact in
                    if contact.birthday == nil {
                        addMissingCard(contact: $contact, screenheight: geometry.size.height)
                    }
                }
                if contactsVM.contactsWithoutBirthday.count == 0 {
                    Text("🎉 No Birthdays Missing 🎉").bold().font(.system(size: 20)).foregroundStyle(.white).padding()
                }
                Spacer()
            }.frame(width: geometry.size.width, height: geometry.size.height).background(Color.black)
        }
    }
}

struct addMissingCard: View {
    @Binding var contact: Contact
    var screenheight : CGFloat
    var phoneNumber: String {
        contact.phoneNumber ?? ""
    }
    @State private var showSheet = false
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                .frame(height: screenheight * 0.20)
            HStack {
                VStack (alignment: .leading){
                    Text(contact.name).bold().font(.system(size: 25)).foregroundStyle(.white)
                    Text(phoneNumber).bold().font(.system(size: 20)).foregroundStyle(.gray)
                    Button(action: {showSheet = true}) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.gray)
                                .frame(height: screenheight * 0.05)
                            Text("🗓️ Add Birthday").foregroundStyle(.white)
                        }
                    }.sheet(isPresented: $showSheet) {
                        addMissingCalendar(contact: $contact)
                    }
                }
                Spacer()
            }.padding()
        }.padding()
    }
}

struct addMissingCalendar: View {
    @Binding var contact : Contact
    @State private var selectedDate = Date()
    var body: some View {
        GeometryReader{ geometry in
            VStack{
                Text("Add Missing Birthday").bold().font(.system(size: 25)).foregroundStyle(.white)
                Text("Select a date for \(contact.name)").bold().font(.system(size: 20)).foregroundStyle(.gray)
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .background(Color(white: 0.15))
                    .cornerRadius(16)
                    .padding()
                    .colorScheme(.dark)
                Button(action: {
                    let components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
                    contact.birthday = components
                    
                }){
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.gray)
                            .frame(height: geometry.size.height * 0.05)
                        Text("Save").foregroundStyle(.white)
                    }
                }
            }.frame(width: geometry.size.width, height: geometry.size.height).background(Color.black)

        }
    }
}


// MARK: - Browse + Calendar (unchanged)

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
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Browse Birthdays")
                                .font(.title3).fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text("View by month or calendar")
                                .font(.footnote).foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }

                HStack(spacing: 8) {
                    Button(action: { selectedTab = .byMonth }) {
                        Text("By Month")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundColor(selectedTab == .byMonth ? .black : .gray)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(selectedTab == .byMonth ? Color.white : Color(white: 0.15))
                            .cornerRadius(12)
                    }
                    Button(action: { selectedTab = .calendar }) {
                        Text("Calendar")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundColor(selectedTab == .calendar ? .black : .gray)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(selectedTab == .calendar ? Color.white : Color(white: 0.15))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                if selectedTab == .byMonth {
                    ByMonthView(selectedMonth: $selectedMonth, months: months, contactsVM: contactsVM)
                } else {
                    CalendarView(selectedDate: $selectedDate, contactsVM: contactsVM)
                }

                Spacer()
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
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Month").font(.footnote).foregroundColor(.gray)
                    .padding(.horizontal)
                HStack {
                    Picker("Select Month", selection: $selectedMonth) {
                        ForEach(months, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color(white: 0.15)).cornerRadius(10)
                    .frame(width: 300)
                    Spacer()
                }
                .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("\(selectedMonth) Birthdays")
                    .font(.headline).foregroundColor(.white)
                    .padding(.horizontal)

                ScrollView {
                    ForEach(contactsVM.contactsPerMonth(monthName: selectedMonth)) { contact in
                        monthCard(contact: contact)
                    }
                }
            }
            .padding(.top, 10)
        }
    }

    func monthCard(contact: Contact) -> some View {
        VStack(alignment: .leading) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.25))
                    .frame(width: 50, height: 50)
                    .overlay(
                        VStack {
                            Text(contact.comparableBirthday!.monthAbbrev())
                                .font(.caption2).foregroundColor(.gray)
                            Text(contact.comparableBirthday!.day())
                                .font(.headline).foregroundColor(.white)
                        }
                    )
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

@available(iOS 17.0, *)
struct CalendarView: View {
    @Binding var selectedDate: Date
    var contactsVM: ContactViewModel

    var body: some View {
        VStack(spacing: 16) {
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .background(Color(white: 0.15))
                .cornerRadius(16)
                .padding(.horizontal)
                .colorScheme(.dark)

            VStack(alignment: .leading, spacing: 8) {
                Text("Selected: \(selectedDate.formattedDate())")
                    .foregroundColor(.gray).font(.footnote)
                    .padding(.horizontal)

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.15))
                    .frame(height: 80)
                    .overlay(
                        ForEach(contactsVM.contactsPerDate(date: selectedDate)) { contact in
                            calendarCard(name: contact.name)
                        }
                    )
                    .padding(.horizontal)
            }
        }
    }

    func calendarCard(name: String) -> some View {
        VStack(alignment: .leading) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.25))
                    .frame(width: 50, height: 50)
                    .overlay(
                        VStack {
                            Text(selectedDate.monthAbbrev())
                                .font(.caption2).foregroundColor(.gray)
                            Text(selectedDate.day())
                                .font(.headline).foregroundColor(.white)
                        }
                    )
                VStack(alignment: .leading, spacing: 4) {
                    Text(name).foregroundColor(.white).fontWeight(.semibold)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

