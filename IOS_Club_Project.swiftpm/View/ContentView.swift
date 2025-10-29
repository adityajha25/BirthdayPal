import Contacts
import SwiftUI

struct ContentView: View {
    @State private var contacts: [CNContact] = []
    
    var body: some View {
        List(contacts, id: \.identifier) { contact in
            Text("\(contact.givenName) \(contact.familyName)")
        }
        .task {
            await requestAccessAndLoadContacts()
        }
    }

    func requestAccessAndLoadContacts() async {
        let store = CNContactStore()
        do {
            let granted = try await store.requestAccess(for: .contacts)
            guard granted else {
                print("Access denied")
                return
            }

            let keys = [CNContactGivenNameKey, CNContactFamilyNameKey] as [CNKeyDescriptor]
            let request = CNContactFetchRequest(keysToFetch: keys)
            var fetched: [CNContact] = []
            try store.enumerateContacts(with: request) { contact, _ in
                fetched.append(contact)
            }
            contacts = fetched
        } catch {
            print("Error: \(error)")
        }
    }
}
