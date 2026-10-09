//
//  PersistenceError.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 5/3/24.
//

import Foundation

enum PersistenceError: Error {
    case entityError // PersistenceManger Load Failed
    case fetchError
    case addError
}

extension PersistenceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .addError: return String(localized: "error.favoriteMissingData")
        case .entityError: return String(localized: "error.favoriteStorage")
        case .fetchError: return String(localized: "error.fetchFailed")
        }
    }
}
