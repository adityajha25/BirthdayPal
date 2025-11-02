//
//  ContentView.swift
//  Birthday
//
//  Created by Aditya Jha    on 10/29/25.
//

import SwiftUI
import Combine

// ViewModel to fetch and manage contacts
class ContactsViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let contactsManager = ContactsManager()
    
    init() {
        fetchContacts()
    }
    
    func fetchContacts() {
        isLoading = true
        contactsManager.fetchContactsSortedByBirthday { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let sortedContacts):
                    self?.contacts = sortedContacts
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.contacts = []
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var contactsVM = ContactsViewModel()

    var body: some View {
        BirthdaySenderView(allContacts: contactsVM.contacts)
    }
}

#Preview {
    ContentView()
}
