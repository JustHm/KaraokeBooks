//
//  HomeList.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/09.
//

import Foundation

enum HomeList: CaseIterable {
    case favourite
    case search

    var localizedTitle: String {
        switch self {
        case .favourite:
            return String(localized: "favorite.title")
        case .search:
            return String(localized: "home.searchSongs")
        }
    }
}

