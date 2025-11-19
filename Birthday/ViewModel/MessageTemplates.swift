//
//  MessageTemplates.swift
//  Birthday
//
//  Created by Archit Lakhani on 11/12/25.
//

import Foundation

enum MessageTone: String, CaseIterable, Identifiable {
    case formal, casual, funny, romantic
    var id: String { rawValue }
}


struct MessageTemplates {
    static func make(tone: MessageTone, name: String, age: Int?) -> String {
        switch tone {
        case .formal:
            return "Happy birthday, \(name). Wishing you a wonderful year ahead."
        case .casual:
            if let age {
                return "Happy birthday, \(name)! You're now \(age). Hope it's a great one 🎉"
            } else {
                return "Happy birthday, \(name)! Hope it's a great one 🎉"
            }
        case .funny:
            return "HBD \(name)! Another lap around the sun — level \(age ?? 0) unlocked 🥳"
        case .romantic:
            return "Happy birthday, \(name) ❤️ So grateful for you—hope today is perfect."
        }
    }
}
