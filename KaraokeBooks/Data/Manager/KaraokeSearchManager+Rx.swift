//
//  KaraokeSearchManager+Rx.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation
import RxSwift

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
