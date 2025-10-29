//
//  AccessContacts.swift
//
//
//  Created by Aditya Jha    on 10/29/25.
//

import Contacts
import UIKit

let store = CNContactStore()

store.requestAccess(for: .contacts) { granted, error in
    guard granted else {
        print("Access denied or error: \(String(describing: error))")
        return
    }
