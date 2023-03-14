//
//  KaraokeSearchInfo.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation

struct KaraokeSearchInfo {
    private let host = "https://api.manana.kr/karaoke/"
    ///  Karaoke API URL Generator (최신곡, 가수, 노래 검색)
    /// - Parameters:
    ///   - query: 검색어 (최신곡 검색시 YYYYMM 또는 YYYYMMDD)
    ///   - searchType: 검색 유형
    func searchURL(query: String, searchType: SearchType) -> URL? {
        let str = host + "\(searchType.rawValue)/" + "\(query).json"
        // 한글 | 공백이 들어갈 경우 nil이 되어서 addingPercentEncoding 작업을 해줌.
        guard let encodedURLStr = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLStr) else {
            return nil
        }
        return url
    }
    /// Karaoke API URL Generator (인기순)
    /// - Parameters:
    ///   - brand: 노래방 브랜드(TJ, KY)
    ///   - date: 일간, 주간, 월간
    ///   - searchType: 인기순 검색 기본값
    func rankingURL(brand: BrandType, date: RankDateType, _ searchType: SearchType = .popular) -> URL? {
        let url = URL(string: host + "\(searchType.rawValue)/" + "\(brand.rawValue)/" + "\(date.rawValue).json")
        return url
    }
}
