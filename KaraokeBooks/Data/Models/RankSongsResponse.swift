//
//  RankSongsResponse.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation

/// Popular charts can contain empty arrays where the provider has no song data.
struct RankSongsResponse: Decodable {
    let songs: [Song]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var songs: [Song] = []
        while !container.isAtEnd {
            let itemDecoder = try container.superDecoder()
            if let emptyArray = try? itemDecoder.unkeyedContainer(), emptyArray.isAtEnd {
                continue
            }
            songs.append(try Song(from: itemDecoder))
        }
        self.songs = songs
    }
}
