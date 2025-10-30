//
//  ContentView.swift
//  Birthday
//
//  Created by Aditya Jha    on 10/29/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var contactsVM = //Add the ViewModel to access contacts here please

    var body: some View {
        BirthdaySenderView(allContacts: contactsVM.contacts)
    }
}

#Preview {
    ContentView()
}
