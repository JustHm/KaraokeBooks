//
//  SearchScopeType.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 12/7/24.
//

import Foundation

enum SearchScopeType: CaseIterable {
    case title, singer

    var localizedTitle: String {
        switch self {
        case .title:
            return String(localized: "search.bySong")
        case .singer:
            return String(localized: "search.byArtist")
        }
    }
}
