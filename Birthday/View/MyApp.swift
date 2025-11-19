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
            NotificationsManager.shared.setUp()
        }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
