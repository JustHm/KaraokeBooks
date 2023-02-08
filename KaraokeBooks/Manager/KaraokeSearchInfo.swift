//
//  KaraokeSearchInfo.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation

struct KaraokeSearchInfo {
    private let host = "https://api.manana.kr/karaoke/"
    ///param - brand, (release의 query는 YYYYMM | YYYYMMDD )
    func searchURL(query: String, searchType: SearchType) -> URL? {
        let str = host + "\(searchType.rawValue)/" + "\(query).json"
        // 한글 | 공백이 들어갈 경우 nil이 되어서 addingPercentEncoding 작업을 해줌.
        guard let encodedURLStr = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLStr) else {
            return nil
        }
        return url
    }
    ///searchType은 popular(인기순) 고정, date: daily, weekly, monthly. 파라미터 없음
    func rankingURL(brand: BrandType, date: RankDateType, _ searchType: SearchType = .popular) -> URL? {
        let url = URL(string: host + "\(searchType.rawValue)/" + "\(brand.rawValue)/" + "\(date.rawValue).json")
        return url
    }
}
