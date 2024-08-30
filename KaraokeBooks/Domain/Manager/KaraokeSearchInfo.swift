//
//  KaraokeSearchInfo.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation

struct KaraokeSearchInfo {
    //https://api.manana.kr/v2/karaoke/search.json?brand=tj&title=사랑&limit=20&page=1
    ///  Karaoke API URL Generator (가수, 노래 검색)
    /// - Parameters:
    ///   - query: 검색어 (최신곡 검색시 YYYYMM 또는 YYYYMMDD)
    ///   - searchType: 검색 유형
    func searchURL(brand: BrandType, query: String, searchType: SearchType, page: Int) -> URL? {
        let host = "https://api.manana.kr/v2/karaoke/"
        let str = host + "search.json?" + "brand=\(brand.rawValue)&" + "\(searchType.rawValue)=\(query)" + "&page=\(page)&limit=20"
        guard let encodedURLStr = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLStr) else { return nil }
        return url
    }
    ///  Karaoke API URL Generator (최신곡)
    /// - Parameters:
    ///   - query: 검색어 (최신곡 검색시 YYYYMM 또는 YYYYMMDD)
    ///   - searchType: 검색 유형
    ///   https://api.manana.kr/v2/karaoke/release.json?release=202408&brand=kumyoung
    func recentURL(brand: BrandType, query: String, searchType: SearchType, page: Int) -> URL? {
        let host = "https://api.manana.kr/v2/karaoke/"
        let str = host + "release.json?" + "\(searchType.rawValue)=\(query)" + "&brand=\(brand.rawValue)" + "&page=\(page)&limit=20"
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
