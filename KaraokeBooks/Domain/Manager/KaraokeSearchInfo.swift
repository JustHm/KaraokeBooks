//
//  KaraokeSearchInfo.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation

//        "brand": "joysound",
//        "no": "918878",
//        "title": "Darling Missing",
//        "singer": "ZELDA",
//        "composer": "小澤亜子",
//        "lyricist": "高橋佐代子",
//        "release": "2012-06-18"

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

/*
 https://api.manana.kr/karaoke/release/202404/kumyoung.json
 https://api.manana.kr/karaoke/song/{title}/kumyoung.json
 https://api.manana.kr/karaoke/singer/{singer}/kumyoung.json
 https://api.manana.kr/karaoke/popular/{brand}/{period}.json
 https://api.manana.kr/karaoke/singer/{singer}/kumyoung.json
 
 https://api.manana.kr/v2/karaoke/search.json?brand=tj&singer=서시
 https://api.manana.kr/v2/karaoke/search.json?brand=tj&title=서시
 https://api.manana.kr/v2/karaoke/search.json?brand=tj&title=%EC%84%9C%EC%8B%9C
 brand=\(brand)&singer=\(singer)
 */
