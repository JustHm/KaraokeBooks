//
//  KaraokeSearchManager.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation
import Alamofire
import RxSwift

enum NetworkError: Error {
    case rankLoadFailed
    case searchFailed
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .rankLoadFailed: return "인기차트 불러오기 실패."
        case .searchFailed: return "노래 검색 실패."
        }
    }
}


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

final class KaraokeSearchManager: ReactiveCompatible, KaraokeSearchManagerProtocol {
    static var shared: KaraokeSearchManager = KaraokeSearchManager()
    private let searchURL = KaraokeSearchInfo()
    
    func rankRequest(brand: BrandType, date: RankDateType) async throws -> [Song] {
        guard let url = searchURL.rankingURL(brand: brand, date: date) else {
            throw KaraokeError.invalidURL
        }
        let dataTask = AF.request(url, method: .get).serializingDecodable([Song].self)
        switch await dataTask.result {
        case .success(let data):
            return data
        case .failure:
            throw NetworkError.rankLoadFailed
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
        case .failure:
            throw NetworkError.searchFailed //AFError
        }
    }
    func searchRequestAll(brand: BrandType, query: String, searchType: SearchType) async throws -> [Song] {
        guard let url = searchURL.searchURLV1(brand: brand, query: query, searchType: searchType) else { throw KaraokeError.invalidURL }
        let dataTask = AF.request(url, method: .get).serializingDecodable([Song].self)
        switch await dataTask.result {
        case .success(let data):
            return data
        case .failure(let error):
            print(error.localizedDescription)
            throw NetworkError.searchFailed //AFError
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

extension Reactive where Base == KaraokeSearchManager {
    func rankSongsRequest(brand: BrandType, date: RankDateType) -> Single<[Song]> {
        return Single.create { single in
            let task = Task {
                do {
                    let response = try await self.base.rankRequest(brand: brand, date: date)
                    single(.success(response))
                }
                catch {
                    single(.failure(error))
                }
            }
            return Disposables.create {
                task.cancel()
            }
        }
    }
    func searchReqeust(brand: BrandType, searchType: SearchType, query: String, page: Int) -> Single<[Song]> {
        return Single.create { single in
            let task = Task {
                do {
                    let response = try await self.base.searchReqeust(brand: brand, query: query, searchType: searchType, page: page)
                    single(.success(response))
                }
                catch {
                    single(.failure(error))
                }
            }
            return Disposables.create {
                task.cancel()
            }
        }
    }
    func searchReqeustAll(brand: BrandType, searchType: SearchType, query: String) -> Single<[Song]> {
        return Single.create { single in
            let task = Task {
                do {
                    let response = try await self.base.searchRequestAll(brand: brand, query: query, searchType: searchType)
                    single(.success(response))
                }
                catch {
                    single(.failure(error))
                }
            }
            return Disposables.create {
                task.cancel()
            }
        }
    }
//    func recentRequest(brand: BrandType, query: String, searchType: SearchType, page: Int) -> Single<[Song]> {
//        return Single.create { single in
//            let task = Task {
//                do {
//                    let response = try await self.base.recentRequest(brand: brand, query: query, searchType: searchType, page: page)
//                    single(.success(response))
//                }
//                catch {
//                    single(.failure(error))
//                }
//            }
//            return Disposables.create {
//                task.cancel()
//            }
//        }
//    }
}
