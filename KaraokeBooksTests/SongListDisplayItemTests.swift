//
//  SongListDisplayItemTests.swift
//  KaraokeBooksTests
//
//  Created by 안정흠 on 2026/08/31.
//

import XCTest
@testable import KaraokeBooks

final class SongListDisplayItemTests: XCTestCase {
    func testDoesNotInsertNativeAdWhenThereAreNoSongs() {
        let items = makeSongs(count: 0).displayItems(nativeAdCount: 1)

        XCTAssertEqual(items.count, 0)
        XCTAssertFalse(items.contains { item in
            if case .nativeAd = item { return true }
            return false
        })
    }

    func testInsertsNativeAdAfterFirstSongWhenThereIsOneSong() {
        let songs = makeSongs(count: 1)
        let items = songs.displayItems(nativeAdCount: 1)

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[1], .nativeAd(slot: 0))
    }

    func testInsertsNativeAdAfterSecondSongWhenThereAreTwoToFourSongs() {
        let songs = makeSongs(count: 4)
        let items = songs.displayItems(nativeAdCount: 1)

        XCTAssertEqual(items.count, 5)
        XCTAssertEqual(items[2], .nativeAd(slot: 0))
        XCTAssertEqual(items[3].song, songs[2])
    }

    func testInsertsNativeAdAfterFifthSongWhenThereAreAtLeastFiveSongs() {
        let songs = makeSongs(count: 6)
        let items = songs.displayItems(nativeAdCount: 1)

        XCTAssertEqual(items.count, 7)
        XCTAssertEqual(items[5], .nativeAd(slot: 0))
        XCTAssertEqual(items[6].song, songs[5])
    }

    func testSongIdentityIsPreservedAfterNativeAdInsertion() {
        let songs = makeSongs(count: 10)
        let items = songs.displayItems(nativeAdCount: 1)

        XCTAssertEqual(items[4].song, songs[4])
        XCTAssertNil(items[5].song)
        XCTAssertEqual(items[6].song, songs[5])
        XCTAssertEqual(items[6].rank, 5)
    }

    func testDoesNotInsertNativeAdWhenItIsUnavailable() {
        let songs = makeSongs(count: 10)
        let items = songs.displayItems(nativeAdCount: 0)

        XCTAssertEqual(items.count, songs.count)
        XCTAssertEqual(items.compactMap(\.song), songs)
    }

    func testInsertsNativeAdEveryFiveSongsWithoutANumericLimit() {
        let songs = makeSongs(count: 20)
        let items = songs.displayItems(nativeAdCount: songs.nativeAdSlotCount)

        XCTAssertEqual(items[5], .nativeAd(slot: 0))
        XCTAssertEqual(items[11], .nativeAd(slot: 1))
        XCTAssertEqual(items[17], .nativeAd(slot: 2))
        XCTAssertEqual(items[23], .nativeAd(slot: 3))
        XCTAssertEqual(items.compactMap(\.song), songs)
    }

    private func makeSongs(count: Int) -> [Song] {
        (0..<count).map { index in
            Song(
                brand: .tj,
                no: "\(index)",
                title: "노래 \(index)",
                singer: "가수 \(index)",
                composer: "작곡가",
                lyricist: "작사가",
                release: "2026"
            )
        }
    }
}
