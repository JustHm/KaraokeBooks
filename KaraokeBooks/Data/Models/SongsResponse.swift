//
//  SongsResponse.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation

struct SongsResponse: Decodable, Equatable {
    let data: [Song]
    let page: Int
}

extension SongsResponse {
    static func == (lhs: SongsResponse, rhs: SongsResponse) -> Bool {
        if lhs.data == rhs.data && lhs.page == rhs.page { return true }
        else { return false }
    }
}
