//
//  KaraokeSearchManagerProtocol.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation

protocol KaraokeSearchManagerProtocol {
    func rankRequest(brand: BrandType,
                     date: RankDateType) async throws -> [Song]
    /// 페이징 없이 검색어에 연관된 모든 노래 반환
    func searchRequestAll(brand: BrandType,
                          query: String,
                          searchType: SearchType) async throws -> [Song]
    /// 검색어에 연관된 모든 노래 반환 (페이징 있음)
    func searchReqeust(brand: BrandType,
                       query: String,
                       searchType: SearchType,
                       page: Int) async throws -> [Song]
    func recentRequest(brand: BrandType,
                       query: String,
                       searchType: SearchType,
                       page: Int) async throws -> [Song]
}
