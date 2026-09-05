//
//  RankChartRepository.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/09/05.
//

import Foundation
import RxSwift

struct RankChartCacheKey: Hashable {
    let brand: BrandType
    let date: RankDateType

    var cacheKey: NSString {
        "\(brand.rawValue).\(date.cacheIdentifier)" as NSString
    }
}

final class RankChartCacheEntry: NSObject {
    let songs: [Song]

    init(songs: [Song]) {
        self.songs = songs
    }
}

protocol RankChartProviding {
    func chart(brand: BrandType, date: RankDateType) -> Single<[Song]>
    func prefetch(brand: BrandType, date: RankDateType)
}

final class RankChartRepository: RankChartProviding {
    private let service: KaraokeSongSearching
    private let cache = NSCache<NSString, RankChartCacheEntry>()
    private let lock = NSLock()
    private var inFlightRequests: [RankChartCacheKey: Single<[Song]>] = [:]
    private let prefetchDisposeBag = DisposeBag()

    init(service: KaraokeSongSearching) {
        self.service = service
        cache.countLimit = BrandType.allCases.count * RankDateType.allCases.count
    }

    func chart(brand: BrandType, date: RankDateType) -> Single<[Song]> {
        let key = RankChartCacheKey(brand: brand, date: date)

        if let cachedSongs = cache.object(forKey: key.cacheKey)?.songs {
            return .just(cachedSongs)
        }

        return requestChart(for: key)
    }

    func prefetch(brand: BrandType, date: RankDateType) {
        let key = RankChartCacheKey(brand: brand, date: date)
        guard cache.object(forKey: key.cacheKey) == nil else { return }

        requestChart(for: key)
            .subscribe()
            .disposed(by: prefetchDisposeBag)
    }
}

private extension RankChartRepository {
    func requestChart(for key: RankChartCacheKey) -> Single<[Song]> {
        lock.lock()
        defer { lock.unlock() }

        if let request = inFlightRequests[key] {
            return request
        }

        let request = service.rankSongsRequest(brand: key.brand, date: key.date)
            .asObservable()
            .do(
                onNext: { [weak self] songs in
                    self?.cache.setObject(
                        RankChartCacheEntry(songs: songs),
                        forKey: key.cacheKey
                    )
                },
                onDispose: { [weak self] in
                    self?.removeInFlightRequest(for: key)
                }
            )
            .share(replay: 1, scope: .whileConnected)
            .asSingle()

        inFlightRequests[key] = request
        return request
    }

    func removeInFlightRequest(for key: RankChartCacheKey) {
        lock.lock()
        inFlightRequests[key] = nil
        lock.unlock()
    }
}
