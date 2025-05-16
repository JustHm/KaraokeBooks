//
//  KaraokeSearchInfo.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation

struct KaraokeSearchInfo {
    let hostV1 = "https://api.manana.kr/karaoke/"
    let hostV2 = "https://api.manana.kr/v2/karaoke/"
    
    //https://api.manana.kr/karaoke/singer/{singer}.json?brand=kumyoung
    //https://api.manana.kr/karaoke/song/{title}.json?brand=kumyoung
    func searchURLV1(brand: BrandType, query: String, searchType: SearchType) -> URL? {
        var str = hostV1
        switch searchType {
        case .title: str += "song/" + "\(query).json" + "?brand=\(brand.rawValue)"
        case .singer: str += "singer/" + "\(query).json" + "?brand=\(brand.rawValue)"
        default: return nil
        }
        guard let encodedURLStr = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLStr) else { return nil }
        return url
    }
    
    //https://api.manana.kr/v2/karaoke/search.json?brand=tj&title=사랑&limit=20&page=1
    ///  Karaoke API URL Generator (가수, 노래 검색)
    /// - Parameters:
    ///   - query: 검색어 (최신곡 검색시 YYYYMM 또는 YYYYMMDD)
    ///   - searchType: 검색 유형
    func searchURL(brand: BrandType, query: String, searchType: SearchType, page: Int) -> URL? {
        let str = hostV2 + "search.json?" + "brand=\(brand.rawValue)&" + "\(searchType.rawValue)=\(query)" + "&page=\(page)&limit=20"
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
        let str = hostV2 + "release.json?" + "\(searchType.rawValue)=\(query)" + "&brand=\(brand.rawValue)" + "&page=\(page)&limit=20"
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
        let str = hostV1 + "\(searchType.rawValue)/" + "\(brand.rawValue)/" + "\(date.replace).json"
        guard let encodedURLStr = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLStr) else { return nil }
        return url
    }
}
