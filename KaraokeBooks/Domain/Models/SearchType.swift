//
//  SearchType.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 12/7/24.
//

import Foundation

/// 노래 검색 종류 (URL에 들어감)
enum SearchType: String {
    case title, singer
    case popular, release//, no
}

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
