//
//  DateExt.swift
//  BirthdayUI
//
//  Created by Jaden Tran on 10/31/25.
//

import Foundation

extension Date {
    func formattedMonthDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
}
