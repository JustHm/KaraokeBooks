//
//  Song.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation

struct SongsResponse: Decodable, Equatable {
    static func == (lhs: SongsResponse, rhs: SongsResponse) -> Bool {
        if lhs.data == rhs.data && lhs.data == rhs.data { return true }
        else { return false }
    }
    
    let data: [Song]
    let page: Int
}

/// 노래검색 Response Model
struct Song: Codable, Identifiable, Equatable {
    var id: String { return String(brand.name + no) }
    let brand: BrandType
    let no: String
    let title: String
    let singer: String
    let composer: String
    let lyricist: String
    let release: String
    var isStar: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case brand, no, title, singer, composer, lyricist, release
    }
}
