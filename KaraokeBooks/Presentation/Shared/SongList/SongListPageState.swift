//
//  SongListPageState.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/09/05.
//

import Foundation

struct SongListPageState: Equatable {
    var songs: [Song] = []
    var hasLoaded = false
    var isLoading = false
    var errorDescription: String?
}
