//
//  KaraokeSearchInfoTests.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/08/30.
//

import XCTest
@testable import KaraokeBooks

final class KaraokeSearchInfoTests: XCTestCase {
    private let searchInfo = KaraokeSearchInfo()

    func testV1SearchURLKeepsReservedCharactersInsideSearchPathComponent() throws {
        let url = try XCTUnwrap(
            searchInfo.searchURLV1(
                brand: .tj,
                query: "A/B?C&D#E%F",
                searchType: .title
            )
        )

        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.percentEncodedPath, "/karaoke/song/A%2FB%3FC&D%23E%25F.json")
        XCTAssertEqual(components.queryItems, [URLQueryItem(name: "brand", value: "tj")])
    }

    func testV2SearchURLEncodesReservedCharactersAsAQueryValue() throws {
        let url = try XCTUnwrap(
            searchInfo.searchURL(
                brand: .kumyoung,
                query: "A&B?C#D",
                searchType: .singer,
                page: 2
            )
        )

        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.path, "/v2/karaoke/search.json")
        XCTAssertEqual(
            components.queryItems,
            [
                URLQueryItem(name: "brand", value: "kumyoung"),
                URLQueryItem(name: "singer", value: "A&B?C#D"),
                URLQueryItem(name: "page", value: "2"),
                URLQueryItem(name: "limit", value: "20")
            ]
        )
    }

    func testJapaneseBrandsDecodeAndKeepHyphenatedSongNumbers() throws {
        for brand in [BrandType.dam, .joysound] {
            let json = """
            {"brand":"\(brand.rawValue)","no":"5535-77","title":"日本語の曲","singer":"歌手","composer":"","lyricist":"","release":"0000-00-00"}
            """
            let song = try JSONDecoder().decode(Song.self, from: Data(json.utf8))
            XCTAssertEqual(song.brand, brand)
            XCTAssertEqual(song.no, "5535-77")
            XCTAssertEqual(BrandType.currentByName(name: brand.name), brand)
            let url = try XCTUnwrap(searchInfo.searchURL(brand: brand, query: song.title, searchType: .title, page: 1))
            let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
            XCTAssertTrue(components.queryItems?.contains(URLQueryItem(name: "brand", value: brand.rawValue)) == true)
        }
    }

    func testRankResponseSkipsOnlyEmptyArrayPlaceholders() throws {
        let json = """
        [[],{"brand":"dam","no":"5277-09","title":"怪獣の花唄","singer":"Vaundy","composer":"","lyricist":"","release":"2020-07-07"},[]]
        """
        let response = try JSONDecoder().decode(RankSongsResponse.self, from: Data(json.utf8))
        XCTAssertEqual(response.songs.map(\.no), ["5277-09"])
        XCTAssertThrowsError(try JSONDecoder().decode(RankSongsResponse.self, from: Data("[{}]".utf8)))
        XCTAssertThrowsError(try JSONDecoder().decode(RankSongsResponse.self, from: Data("[[1]]".utf8)))
    }

}
