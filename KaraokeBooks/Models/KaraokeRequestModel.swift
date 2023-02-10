//
//  KaraokeRequestModel.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/10.
//

import Foundation

enum SearchType: String {
    case song, singer, popular
    case release//, no
}

struct KaraokeRequestModel: Codable {
    let brand: String
}
