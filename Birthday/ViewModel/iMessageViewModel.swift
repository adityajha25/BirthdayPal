//
//  ContactViewModel.swift
//  BirthdayUI
//
//  Created by Jaden Tran on 11/3/25.
//

import Foundation
import Combine

@available(iOS 17.0, *)
@Observable class ContactViewModel {
    
    var contacts: [Contact]
    var isLoading: Bool = false
    var errorMessage: String?
    
    private let contactsManager = ContactsManager()
    
    init(contacts: [Contact] = []) {
        self.contacts = contacts
    }
    
    /// Fetches contacts from the device and populates the view model
    func loadContacts() {
        isLoading = true
        errorMessage = nil
        
        contactsManager.fetchContactsSortedByBirthday { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let fetchedContacts):
                    self?.contacts = fetchedContacts
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("Error fetching contacts: \(error)")
                }
            }
        }
    }
    
    var sortedUpcoming: [Contact] {
        contacts.sorted {
            guard let d1 = $0.comparableBirthday,
                  let d2 = $1.comparableBirthday else {
                return $0.comparableBirthday != nil
            }
            return d1.nextBirthday() < d2.nextBirthday()
        }
    }
    
    var contactsWithBirthday: [Contact] {
        sortedUpcoming.filter { $0.comparableBirthday != nil }
    }
    
    var contactsWithoutBirthday: [Contact] {
        sortedUpcoming.filter { $0.comparableBirthday == nil }
    }
    
    var birthdaysThisMonthCount: Int {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        
        return contactsWithBirthday.filter {
            guard let month = $0.birthday?.month else { return false }
            return month == currentMonth
        }.count
    }
    
    var birthdaysThisMonth: [Contact] {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        
        return contactsWithBirthday.filter {
            guard let month = $0.birthday?.month else { return false }
            return month == currentMonth
        }
    }
    
    func contactsPerDate(date: Date) -> [Contact] {
        let calendar = Calendar.current
        let targetMonth = calendar.component(.month, from: date)
        let targetDay = calendar.component(.day, from: date)
        
        return contactsWithBirthday.filter {
            guard let birthday = $0.birthday else { return false }
            return birthday.month == targetMonth && birthday.day == targetDay
        }
    }
    
    func contactsPerMonth(monthName: String) -> [Contact] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        
        guard let monthDate = dateFormatter.date(from: monthName.capitalized) else {
            return []
        }

        let monthNumber = Calendar.current.component(.month, from: monthDate)
        
        return contactsWithBirthday.filter {
            guard let contactMonth = $0.birthday?.month else { return false }
            return contactMonth == monthNumber
        }
    }
}
