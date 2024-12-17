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

enum SearchScopeType: String, CaseIterable {
    case title, singer
    
    var name: String {
        switch self {
        case .title:
            return "노래 검색"
        case .singer:
            return "가수 검색"
//        default:
//            return ""
        }
    }
}
