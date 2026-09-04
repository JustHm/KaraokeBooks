//
//  KaraokeError.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/28.
//

import Foundation

enum KaraokeError: Error {
    case invalidURL
}

extension KaraokeError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "error.invalidURL")
        }
    }
}
