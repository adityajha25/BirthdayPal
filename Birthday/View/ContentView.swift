import SwiftUI
import Contacts
import MessageUI

struct ContentView: View {
    var body: some View {
        if #available(iOS 17.0, *) {
            LandingPage()
        } else {
            // Fallback on earlier versions
        }
    }
}

@available(iOS 17.0, *)
struct LandingPage: View {
    @State var contactsVM = ContactViewModel()

    var body: some View{
        NavigationStack {
            GeometryReader { geometry in
                VStack{
                    HStack{
                        Text("BirthdayPal").foregroundStyle(.white).font(.title)
                        Spacer()
                    }.padding(.horizontal)
                    HStack{
                        Text("Never miss a special day").foregroundStyle(.gray)
                        Spacer()
                    }.padding(.horizontal)
                    HStack{
                        Text("Upcoming").foregroundStyle(.white).font(.title3)
                        Spacer()
                        Text("\(contactsVM.birthdaysThisMonthCount) this month").foregroundStyle(.white).font(.title3)
                    }.padding()
                    
                    // Add loading and error states
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
                            ForEach(contactsVM.contactsWithBirthday) {contact in
                                NavigationLink(destination: editView(contact: contact)) {
                                    BdayCard(contact: contact, screenwidth: geometry.size.width, screenheight: geometry.size.height)
                                }
                            }
                        }
                    }
                    
                    AchievementCardView()
                    
                    NavigationLink(destination: BrowseBirthdaysView(contactsVM: contactsVM)) {
                        browseMonth(screenwidth: geometry.size.width, screenheight: geometry.size.height)
                    }
                    
                }.frame(width: geometry.size.width, height: geometry.size.height).background(.black)
            }
        }
        .onAppear {
            contactsVM.loadContacts()
        }
    }
}

struct browseMonth: View {
    var screenwidth: CGFloat
    var screenheight: CGFloat
    var body: some View {
        ZStack(alignment:.topLeading ) {
            RoundedRectangle(cornerRadius: 20).fill(Color(red: 0.1, green: 0.1, blue: 0.1)).frame(height: screenheight * 0.14)
            HStack {
                ZStack {
                    if #available(iOS 17.0, *) {
                        RoundedRectangle(cornerRadius: 10).fill(.gray).frame(width: screenwidth * 0.2, height: screenwidth * 0.2)
                    } else {
                        // Fallback on earlier versions
                    }
                    Image(systemName: "calendar").resizable().frame(width: screenwidth * 0.1, height: screenheight * 0.05).foregroundColor(.black)
                }.padding()
                VStack {
                    Text("Browse by Month").foregroundStyle(.white)
                    Text("View all birthdays").foregroundStyle(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray).padding()
            }
            
        }.padding(.horizontal)
    }
}

struct AchievementCardView: View {
    var body: some View {
        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                .shadow(radius: 5)

            HStack(alignment: .top) {
                // Left content
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
                        Text("20")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                        Text("birthdays")
                            .font(.title3)
                            .foregroundColor(.white)
                    }

                    Text("Very good! 🎉")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
                .padding(16)

                Spacer()

                Text("🎂")
                    .font(.system(size: 50))
                    .padding(.trailing, 16)
                    .padding(.top, 16)
            }
        }
        .frame(height: 150).padding()
    }
}

struct BdayCard: View {
    var contact : Contact
    var screenwidth : CGFloat
    var screenheight: CGFloat
    var body: some View {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .frame(height: screenheight * 0.16)
                HStack(alignment: .top) {
                    ZStack {
                        if #available(iOS 17.0, *) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.clear)
                                .stroke(.white)
                                .frame(width: screenwidth * 0.125, height: screenwidth * 0.125)
                        } else {
                            // Fallback on earlier versions
                        }
                        VStack {
                            Text("\(contact.comparableBirthday!.formattedMonthDay().split(separator: " ")[0])")
                                .foregroundStyle(.white)
                                .padding(.top, 1)
                            Text("\(contact.comparableBirthday!.formattedMonthDay().split(separator: " ")[1])")
                                .foregroundStyle(.white)
                                .padding(.bottom, 1)
                        }
                    }.frame(width: screenwidth * 0.15, height: screenwidth * 0.15)
                        .padding(.trailing, 4)
                    VStack(alignment: .leading) {
                        Text(contact.name)
                            .bold()
                            .font(.system(size: 25))
                            .foregroundStyle(.white)
                        Text("In \(contact.daysToBirthday!) days").foregroundStyle(.white)
                    }
                    Spacer()
//                    if contact.gender == "male" {
//                        Text("👨").font(.title)
//                    } else if contact.gender == "female" {
//                        Text("👧").font(.title)
//                    }
                }.padding(10)
            }.padding(.horizontal)
    }
}
struct editView: View {
    var contact: Contact
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
            MessageTemplatePickerView(messageVM: messageVM)
        }
        .fullScreenCover(isPresented: $messageVM.showComposer) {
            if MFMessageComposeViewController.canSendText() {
                MessageComposerView(
                    recipients: messageVM.composerRecipients,
                    body: messageVM.composerBody,
                    onFinish: { _ in
                        messageVM.composerFinished()
                        dismiss()
                    }
                )
                .ignoresSafeArea()
            } else {
                VStack(spacing: 20) {
                    Text("Cannot Send Messages")
                        .font(.headline)
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
            Button("OK") {
                messageVM.lastError = nil
            }
        } message: {
            if let error = messageVM.lastError {
                Text(error)
            }
        }
    }
    
    private func convertToCNContact(_ contact: Contact) -> CNContact {
        let cnContact = CNMutableContact()
        
        let nameComponents = contact.name.components(separatedBy: " ")
        if nameComponents.count > 0 {
            cnContact.givenName = nameComponents[0]
        }
        if nameComponents.count > 1 {
            cnContact.familyName = nameComponents[1...].joined(separator: " ")
        }
        
        if let phoneNumber = contact.phoneNumber {
            let phone = CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: phoneNumber))
            cnContact.phoneNumbers = [phone]
        }
        
        if let birthday = contact.birthday {
            cnContact.birthday = birthday
        }
        
        return cnContact.copy() as! CNContact
    }
}
@available(iOS 17.0, *)
struct BrowseBirthdaysView: View {
    @State private var selectedMonth = "January"
    @State private var selectedTab: ViewMode = .byMonth
    @State private var selectedDate = Date()
    var contactsVM : ContactViewModel
    
    enum ViewMode {
        case byMonth
        case calendar
    }
    
    let months = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Browse Birthdays")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text("View by month or calendar")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                
                // Toggle between By Month / Calendar
                HStack(spacing: 8) {
                    Button(action: { selectedTab = .byMonth }) {
                        Text("By Month")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTab == .byMonth ? .black : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedTab == .byMonth ? Color.white : Color(white: 0.15))
                            .cornerRadius(12)
                    }
                    
                    Button(action: { selectedTab = .calendar }) {
                        Text("Calendar")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTab == .calendar ? .black : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedTab == .calendar ? Color.white : Color(white: 0.15))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // Conditional content
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

// MARK: - By Month View
@available(iOS 17.0, *)
struct ByMonthView: View {
    @Binding var selectedMonth: String
    let months: [String]
    var contactsVM : ContactViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Month dropdown
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Month")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                HStack {
                    Picker("Select Month", selection: $selectedMonth) {
                        ForEach(months, id: \.self) { month in
                            Text(month).tag(month)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(white: 0.15))
                    .cornerRadius(10)
                    .frame(width: 160)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // Birthday list placeholder
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(selectedMonth) Birthdays")
                        .font(.headline)
                        .foregroundColor(.white)
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
    
    func monthCard(contact : Contact) -> some View {
        return VStack(alignment: .leading) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.25))
                    .frame(width: 50, height: 50)
                    .overlay(
                        VStack {
                            Text(contact.comparableBirthday!.monthAbbrev())
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(contact.comparableBirthday!.day())
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    Text("Birthday today!")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                Spacer()
            }
            .padding(.horizontal)
        }

    }
}

// MARK: - Calendar View
@available(iOS 17.0, *)
struct CalendarView: View {
    @Binding var selectedDate: Date
    var contactsVM : ContactViewModel
    var body: some View {
        VStack(spacing: 16) {
            // Simple calendar date picker
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .background(Color(white: 0.15))
                .cornerRadius(16)
                .padding(.horizontal)
                .colorScheme(.dark)
            
            // Selected date label
            VStack(alignment: .leading, spacing: 8) {
                Text("Selected: \(selectedDate.formattedDate())")
                    .foregroundColor(.gray)
                    .font(.footnote)
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
        return VStack(alignment: .leading) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.25))
                    .frame(width: 50, height: 50)
                    .overlay(
                        VStack {
                            Text(selectedDate.monthAbbrev())
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(selectedDate.day())
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    Text("Birthday today!")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}
