//
//  SongListDisplayItem.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/08/31.
//

import Foundation

enum SongListDisplayItem: Equatable {
    case song(Song, rank: Int)
    case nativeAd(slot: Int)

    var song: Song? {
        guard case let .song(song, _) = self else { return nil }
        return song
    }

    var rank: Int? {
        guard case let .song(_, rank) = self else { return nil }
        return rank
    }
}

extension Array where Element == Song {
    func displayItems(
        nativeAdCount: Int
    ) -> [SongListDisplayItem] {
        let insertionIndices = nativeAdInsertionIndices.prefix(nativeAdCount)
        var items: [SongListDisplayItem] = []
        for (index, song) in enumerated() {
            items.append(.song(song, rank: index))
            if let slot = insertionIndices.firstIndex(of: index + 1) {
                items.append(.nativeAd(slot: slot))
            }
        }
        return items
    }

    var nativeAdSlotCount: Int {
        nativeAdInsertionIndices.count
    }

    func nativeAdCountToRequest(prefetchingSongAt rank: Int, lookAheadSongCount: Int = 3) -> Int? {
        let prefetchedSongPosition = rank + 1
        guard let lastSlot = nativeAdInsertionIndices.lastIndex(where: {
            $0 <= prefetchedSongPosition + lookAheadSongCount
        }) else { return nil }
        return lastSlot + 1
    }

    private var nativeAdInsertionIndices: [Int] {
        switch count {
        case 0:
            return []
        case 1:
            return [1]
        case 2...4:
            return [2]
        default:
            return [5] + [Int](stride(from: 25, through: count, by: 20))
        }
    }
}
