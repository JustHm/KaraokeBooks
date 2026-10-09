//
//  KaraokeSearchManager.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation
import Alamofire
import RxSwift

final class KaraokeSearchManager: ReactiveCompatible, KaraokeSearchManagerProtocol {
    static var shared: KaraokeSearchManager = KaraokeSearchManager()
    private let searchURL = KaraokeSearchInfo()
    
    func rankRequest(brand: BrandType, date: RankDateType) async throws -> [Song] {
        guard let url = searchURL.rankingURL(brand: brand, date: date) else {
            throw KaraokeError.invalidURL
        }
        let dataTask = AF.request(url, method: .get).serializingDecodable(RankSongsResponse.self)
        switch await dataTask.result {
        case .success(let data):
            return data.songs
        case let .failure(error):
            throw networkError(for: error, fallback: .rankLoadFailed)
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
        case let .failure(error):
            throw networkError(for: error, fallback: .searchFailed)
        }
    }
    func searchRequestAll(brand: BrandType, query: String, searchType: SearchType) async throws -> [Song] {
        guard let url = searchURL.searchURLV1(brand: brand, query: query, searchType: searchType) else { throw KaraokeError.invalidURL }
        let dataTask = AF.request(url, method: .get).serializingDecodable([Song].self)
        switch await dataTask.result {
        case .success(let data):
            return data
        case .failure(let error):
            throw networkError(for: error, fallback: .searchFailed)
        }
    }

    private func networkError(for error: Error, fallback: NetworkError) -> NetworkError {
        let underlyingError = (error as? AFError)?.underlyingError ?? error
        let errorCode = (underlyingError as NSError).code
        let isConnectionError = [
            URLError.Code.notConnectedToInternet.rawValue,
            URLError.Code.networkConnectionLost.rawValue,
            URLError.Code.cannotConnectToHost.rawValue,
            URLError.Code.cannotFindHost.rawValue,
            URLError.Code.dnsLookupFailed.rawValue
        ].contains(errorCode)

        return isConnectionError ? .internetUnavailable : fallback
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

extension KaraokeSearchManager: KaraokeSongSearching {
    func rankSongsRequest(brand: BrandType, date: RankDateType) -> Single<[Song]> {
        rx.rankSongsRequest(brand: brand, date: date)
    }

    func searchSongsRequest(brand: BrandType, query: String, searchType: SearchType) -> Single<[Song]> {
        rx.searchReqeustAll(brand: brand, searchType: searchType, query: query)
    }
}
