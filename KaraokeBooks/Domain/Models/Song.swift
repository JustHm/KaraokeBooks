//
//  Song.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation
/// 노래검색 Response Model
struct Song: Codable, Identifiable {
    var id: String { return UUID().uuidString }
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
