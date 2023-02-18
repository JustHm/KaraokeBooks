//
//  KaraokeRequestModel.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/10.
//

import Foundation

enum SearchType: String {
    case song, singer
    case popular, release//, no
    var title: String {
        switch self {
        case .song:
            return "노래 검색"
        case .singer:
            return "가수 검색"
        default:
            return ""
        }
    }
}

struct KaraokeRequestModel: Codable {
    let brand: String
}
