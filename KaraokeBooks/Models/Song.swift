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



