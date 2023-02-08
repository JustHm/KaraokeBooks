//
//  Song.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation

struct Song: Codable {
    let brand: BrandType
    let no: String
    let title: String
    let singer: String
    let composer: String
    let lyricist: String
    let release: String
}

enum SearchType: String {
    case song, singer, no
    case release, popular
}

struct KaraokeRequestModel: Codable {
    let brand: String
}

enum BrandType: String, CaseIterable, Codable {
    case tj
    case kumyoung
    //case joysound
    //case dam
    //case uga
    
    var replace: String {
        switch self {
        case .tj:
            return "TJ"
        case .kumyoung:
            return "KY"
        }
    }
    
    static var currentBrand: BrandType = .tj
}

enum RankDateType: String, CaseIterable {
    case daily, weekly, monthly
    var replace: String {
        switch self {
        case .daily:
            return "일간"
        case .weekly:
            return "주간"
        case .monthly:
            return "월간"
        }
    }
}
