//
//  Date+.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 5/4/24.
//

import Foundation

extension Date {
    func dateToString(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
