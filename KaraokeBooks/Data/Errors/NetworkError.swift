//
//  NetworkError.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation

enum NetworkError: Error {
    case internetUnavailable
    case rankLoadFailed
    case searchFailed
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .internetUnavailable:
            return String(localized: "error.internetUnavailable")
        case .rankLoadFailed:
            return String(localized: "error.rankLoadFailed")
        case .searchFailed:
            return String(localized: "error.searchFailed")
        }
    }
}
