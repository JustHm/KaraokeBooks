//
//  KaraokeSearchManager.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation
import Alamofire

protocol KaraokeSearchManagerProtocol {
    func rankRequest(brand: BrandType,
                     date: RankDateType) async throws -> [Song]
    func searchReqeust(brand: BrandType,
                       query: String,
                       searchType: SearchType) async throws -> [Song]
}

struct KaraokeSearchManager: KaraokeSearchManagerProtocol {
    private let searchURL = KaraokeSearchInfo()
    func rankRequest(brand: BrandType, date: RankDateType) async throws -> [Song] {
        guard let url = searchURL.rankingURL(brand: brand, date: date) else {
            throw KaraokeError.invalidURL
        }
        let dataTask = AF.request(url, method: .get).serializingDecodable([Song].self)
        switch await dataTask.result {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
    func searchReqeust(brand: BrandType, query: String, searchType: SearchType) async throws -> [Song] {
        guard let url = searchURL.searchURL(query: query, searchType: searchType) else {
            throw KaraokeError.invalidURL
        }
        let param = KaraokeRequestModel(brand: brand.rawValue)
        let dataTask = AF.request(url, method: .get, parameters: param).serializingDecodable([Song].self)
        switch await dataTask.result {
        case .success(let data):
            return data
        case .failure(let error):
            throw error //AFError
        }
    }
}
