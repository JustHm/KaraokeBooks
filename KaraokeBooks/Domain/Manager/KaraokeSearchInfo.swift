//
//  KaraokeSearchInfo.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation

struct KaraokeSearchInfo {
    ///  Karaoke API URL Generator (최신곡, 가수, 노래 검색)
    /// - Parameters:
    ///   - query: 검색어 (최신곡 검색시 YYYYMM 또는 YYYYMMDD)
    ///   - searchType: 검색 유형
    func searchURL(brand: BrandType, query: String, searchType: SearchType) -> URL? {
        let host = "https://api.manana.kr/v2/karaoke/"
        let str = host + "search.json?" + "brand=\(brand.rawValue)&" + "\(searchType.rawValue)=\(query)"
        guard let encodedURLStr = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLStr) else { return nil }
        return url
    }
    func recentURL(brand: BrandType, query: String, searchType: SearchType) -> URL? {
        let host = "https://api.manana.kr/karaoke/"
        let str = host + "release.json?" + "brand=\(brand.rawValue)&" + "\(searchType.rawValue)=\(query)"
        guard let encodedURLStr = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLStr) else { return nil }
        return url
    }
    /// Karaoke API URL Generator (인기순)
    /// - Parameters:
    ///   - brand: 노래방 브랜드(TJ, KY)
    ///   - date: 일간, 주간, 월간
    ///   - searchType: 인기순 검색 기본값
    func rankingURL(brand: BrandType, date: RankDateType, _ searchType: SearchType = .popular) -> URL? {
        let host = "https://api.manana.kr/karaoke/"
        let str = host + "\(searchType.rawValue)/" + "\(brand.rawValue)/" + "\(date.rawValue).json"
        guard let encodedURLStr = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLStr) else { return nil }
        return url
    }
}
