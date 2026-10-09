//
//  KaraokeSongSearching.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import RxSwift

protocol KaraokeSongSearching {
    func rankSongsRequest(brand: BrandType, date: RankDateType) -> Single<[Song]>
    func searchSongsRequest(brand: BrandType, query: String, searchType: SearchType) -> Single<[Song]>
}
