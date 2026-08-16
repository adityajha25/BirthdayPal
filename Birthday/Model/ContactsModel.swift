//
//  ContactsModel.swift
//  Birthday
//
//  Created by Aditya Jha    on 11/2/25.
//
import Foundation
import Contacts
import Combine

/// Represents a contact with essential information
struct Contact: Identifiable, Hashable {
    let id: String
    let name: String
    let phoneNumber: String?
    var birthday: DateComponents?
    
    init(id: String, name: String, phoneNumber: String?, birthday: DateComponents?) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.birthday = birthday
    }
    
    /// Next date this birthday is observed (Feb 29 → Feb 28 in non-leap years).
    var comparableBirthday: Date? {
        nextObservanceDate()
    }
    
    var daysToBirthday: Int? {
        guard let nextBirthdayDate = nextObservanceDate() else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.dateComponents([.day], from: today, to: nextBirthdayDate).day
    }
    
    /// Age the person will turn on their next birthday. `nil` when birth year is unknown.
    var ageTurning: Int? {
        guard let birthYear = birthday?.year,
              let next = nextObservanceDate() else { return nil }
        let nextYear = Calendar.current.component(.year, from: next)
        let age = nextYear - birthYear
        return age > 0 ? age : nil
    }
    
    /// Month/day for display badges (uses a leap year so Feb 29 always formats).
    var displayBirthdayDate: Date? {
        guard let month = birthday?.month, let day = birthday?.day else { return nil }
        var comps = DateComponents()
        comps.year = 2024 // leap year — keeps Feb 29 valid for display
        comps.month = month
        comps.day = day
        return Calendar.current.date(from: comps)
    }
    
    /// Whether this contact's birthday is observed on the given calendar day.
    func isObserved(on date: Date, calendar: Calendar = .current) -> Bool {
        guard let observance = observanceDate(
            in: calendar.component(.year, from: date),
            calendar: calendar
        ) else { return false }
        return calendar.isDate(observance, inSameDayAs: date)
    }
    
    /// Observed celebration date in a specific year.
    /// Leap-day birthdays fall on Feb 28 in non-leap years.
    func observanceDate(in year: Int, calendar: Calendar = .current) -> Date? {
        guard let month = birthday?.month, let day = birthday?.day else { return nil }
        var adjustedDay = day
        if month == 2 && day == 29 && !Self.isLeapYear(year, calendar: calendar) {
            adjustedDay = 28
        }
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = adjustedDay
        return calendar.date(from: comps)
    }
    
    func nextObservanceDate(from reference: Date = Date(), calendar: Calendar = .current) -> Date? {
        guard birthday?.month != nil, birthday?.day != nil else { return nil }
        let today = calendar.startOfDay(for: reference)
        let year = calendar.component(.year, from: today)
        
        if let thisYear = observanceDate(in: year, calendar: calendar),
           calendar.startOfDay(for: thisYear) >= today {
            return calendar.startOfDay(for: thisYear)
        }
        guard let nextYear = observanceDate(in: year + 1, calendar: calendar) else { return nil }
        return calendar.startOfDay(for: nextYear)
    }
    
    /// Month/day used for repeating calendar notifications (Feb 29 → 28 so it fires yearly).
    var notificationMonthDay: (month: Int, day: Int)? {
        guard let month = birthday?.month, let day = birthday?.day else { return nil }
        if month == 2 && day == 29 {
            return (2, 28)
        }
        return (month, day)
    }
    
    static func isLeapYear(_ year: Int, calendar: Calendar = .current) -> Bool {
        var comps = DateComponents()
        comps.year = year
        comps.month = 2
        comps.day = 29
        return calendar.date(from: comps) != nil
    }
}



/// Manages fetching and sorting contacts
class ContactsManager {
    
    private let contactStore = CNContactStore()
    
    /// Requests access to contacts and fetches them
    /// - Parameter completion: Closure called with array of sorted contacts or error
    func fetchContactsSortedByBirthday(completion: @escaping (Result<[Contact], Error>) -> Void) {
        // Request authorization
        contactStore.requestAccess(for: .contacts) { granted, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard granted else {
                completion(.failure(NSError(domain: "ContactsManager",
                                           code: 403,
                                           userInfo: [NSLocalizedDescriptionKey: "Access to contacts denied"])))
                return
            }
            
            // Move to background thread
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let contacts = try self.performContactsEnumeration()
                    let sortedContacts = contacts.sorted { self.shouldPlaceFirst($0, before: $1) }
                    DispatchQueue.main.async {
                        completion(.success(sortedContacts))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    /// Performs the actual contact enumeration. Must be called off the main thread.
    private func performContactsEnumeration() throws -> [Contact] {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor
        ]
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        var contacts: [Contact] = []
        try contactStore.enumerateContacts(with: request) { cnContact, _ in
            let name = "\(cnContact.givenName) \(cnContact.familyName)".trimmingCharacters(in: .whitespaces)
            let phoneNumber = cnContact.phoneNumbers.first?.value.stringValue
            let birthday = cnContact.birthday
            let contact = Contact(
                id: cnContact.identifier,
                name: name.isEmpty ? "No Name" : name,
                phoneNumber: phoneNumber,
                birthday: birthday
            )
            contacts.append(contact)
        }
        return contacts
    }
    
    /// Contacts with an upcoming birthday come first, ordered by next observance date.
    private func shouldPlaceFirst(_ first: Contact, before second: Contact) -> Bool {
        let firstDate = first.comparableBirthday
        let secondDate = second.comparableBirthday
        
        if let firstDate = firstDate, let secondDate = secondDate {
            return firstDate < secondDate
        }
        if firstDate != nil && secondDate == nil {
            return true
        }
        if firstDate == nil && secondDate != nil {
            return false
        }
        return true
    }
}

extension Date {
    func formattedMonthDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
    
    func nextBirthday() -> Date {
        let today = Calendar.current.startOfDay(for: Date())
        let birthdayDay = Calendar.current.startOfDay(for: self)
        
        return birthdayDay < today
            ? Calendar.current.date(byAdding: .year, value: 1, to: birthdayDay)!
            : birthdayDay
    }
    
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: self)
    }
    
    func monthAbbrev() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: self)
    }
    
    func day() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: self)
    }
}

