//
//  ContactsModel.swift
//  Birthday
//
//  Created by Aditya Jha    on 11/2/25.
//
import Foundation
import Contacts

/// Represents a contact with essential information
struct Contact: Identifiable {
    let id = UUID()
    let name: String
    let phoneNumber: String?
    let birthday: DateComponents?
    
    /// Returns a comparable date for sorting purposes
    /// Converts birthday to a date in the current year for comparison
    var comparableBirthday: Date? {
        guard let birthday = birthday else { return nil }
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        var dateComponents = DateComponents()
        dateComponents.year = currentYear
        dateComponents.month = birthday.month
        dateComponents.day = birthday.day
        
        return calendar.date(from: dateComponents)
    }
    
    var daysToBirthday: Int? {
        guard let nextBirthdayDate = comparableBirthday?.nextBirthday() else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: nextBirthdayDate).day
        return days
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
                    let contacts = try self.getAllContacts()
                    let sortedContacts = self.mergeSortByBirthday(contacts)
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
    
    /// Fetches all contacts from the device
    /// - Returns: Array of Contact structs
    private func getAllContacts() throws -> [Contact] {
        // Ensure we never enumerate contacts on the main thread
        if Thread.isMainThread {
            // Perform the enumeration synchronously on a background queue
            var result: Result<[Contact], Error> = .success([])
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let contacts = try self.performContactsEnumeration()
                    result = .success(contacts)
                } catch {
                    result = .failure(error)
                }
                group.leave()
            }
            group.wait()
            switch result {
            case .success(let contacts):
                return contacts
            case .failure(let error):
                throw error
            }
        } else {
            // Already off the main thread – enumerate directly
            return try self.performContactsEnumeration()
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
            let contact = Contact(name: name.isEmpty ? "No Name" : name,
                                  phoneNumber: phoneNumber,
                                  birthday: birthday)
            contacts.append(contact)
        }
        return contacts
    }
    
    /// Sorts contacts by birthday using merge sort algorithm
    /// Contacts without birthdays are placed at the end
    /// - Parameter contacts: Array of contacts to sort
    /// - Returns: Sorted array of contacts
    func mergeSortByBirthday(_ contacts: [Contact]) -> [Contact] {
        guard contacts.count > 1 else { return contacts }
        
        let middleIndex = contacts.count / 2
        let leftArray = Array(contacts[0..<middleIndex])
        let rightArray = Array(contacts[middleIndex..<contacts.count])
        
        return merge(
            left: mergeSortByBirthday(leftArray),
            right: mergeSortByBirthday(rightArray)
        )
    }
    
    /// Merges two sorted arrays into one sorted array
    /// - Parameters:
    ///   - left: Left sorted array
    ///   - right: Right sorted array
    /// - Returns: Merged sorted array
    private func merge(left: [Contact], right: [Contact]) -> [Contact] {
        var leftIndex = 0
        var rightIndex = 0
        var result: [Contact] = []
        
        // Merge while both arrays have elements
        while leftIndex < left.count && rightIndex < right.count {
            let leftContact = left[leftIndex]
            let rightContact = right[rightIndex]
            
            // Contacts with birthdays come before those without
            if shouldPlaceFirst(leftContact, before: rightContact) {
                result.append(leftContact)
                leftIndex += 1
            } else {
                result.append(rightContact)
                rightIndex += 1
            }
        }
        
        // Append remaining elements
        while leftIndex < left.count {
            result.append(left[leftIndex])
            leftIndex += 1
        }
        
        while rightIndex < right.count {
            result.append(right[rightIndex])
            rightIndex += 1
        }
        
        return result
    }
    
    /// Determines if first contact should be placed before second contact
    /// - Parameters:
    ///   - first: First contact
    ///   - second: Second contact
    /// - Returns: True if first should come before second
    private func shouldPlaceFirst(_ first: Contact, before second: Contact) -> Bool {
        let firstDate = first.comparableBirthday
        let secondDate = second.comparableBirthday
        
        // If both have birthdays, compare dates
        if let firstDate = firstDate, let secondDate = secondDate {
            return firstDate < secondDate
        }
        
        // Contacts with birthdays come before those without
        if firstDate != nil && secondDate == nil {
            return true
        }
        
        if firstDate == nil && secondDate != nil {
            return false
        }
        
        // If neither has a birthday, maintain original order
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
        let today = Date()
        return self < today
            ? Calendar.current.date(byAdding: .year, value: 1, to: self)!
            : self
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

