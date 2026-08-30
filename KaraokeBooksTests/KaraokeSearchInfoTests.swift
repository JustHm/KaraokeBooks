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
}
