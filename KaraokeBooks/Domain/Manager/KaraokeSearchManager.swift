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
                       searchType: SearchType,
                       page: Int) async throws -> [Song]
    func recentRequest(brand: BrandType,
                       query: String,
                       searchType: SearchType,
                       page: Int) async throws -> [Song]
}

final class KaraokeSearchManager: KaraokeSearchManagerProtocol {
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
    func searchReqeust(brand: BrandType, query: String, searchType: SearchType, page: Int) async throws -> [Song] {
        guard let url = searchURL.searchURL(brand: brand, query: query, searchType: searchType, page: page) else {
            throw KaraokeError.invalidURL
        }
        let dataTask = AF.request(url, method: .get).serializingDecodable(SongsResponse.self)
        switch await dataTask.result {
        case .success(let data):
            return data.data
        case .failure(let error):
            throw error //AFError
        }
    }
    
    func recentRequest(brand: BrandType, query: String, searchType: SearchType, page: Int) async throws -> [Song] {
        guard let url = searchURL.recentURL(brand: brand, query: query, searchType: searchType, page: page) else {
            throw KaraokeError.invalidURL
        }
        print(url)
        let dataTask = AF.request(url, method: .get).serializingDecodable([Song].self)
        switch await dataTask.result {
        case .success(let data):
            return data
        case .failure(let error):
            throw error //AFError
        }
    }
}
