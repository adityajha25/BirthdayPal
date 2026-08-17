//
//  MyApp.swift
//  Birthday
//
//  Created by Aditya Jha    on 11/3/25.
//

import Foundation
import SwiftUI

@main
struct MyApp: App {
    init() {
        BirthdayNotificationManager.shared.setUp()
        BirthdayNotificationManager.shared.refreshScheduleFromContactsIfEnabled()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
