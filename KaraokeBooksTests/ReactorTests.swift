//
//  ReactorTests.swift
//  KaraokeBooksTests
//
//  Created by 안정흠 on 2026/08/31.
//

import XCTest
import CoreData
import RxSwift
@testable import KaraokeBooks

final class ReactorTests: XCTestCase {
    private let disposeBag = DisposeBag()

    func testHomeReactorUsesSelectedRankDateAndStoresSongs() {
        let songs = makeSongs(count: 2)
        let service = StubKaraokeSongSearchService(rankResult: .success(songs))
        let reactor = HomeReactor(service: service)
        let expectation = expectation(description: "차트 요청 완료")

        reactor.state
            .filter { $0.popularList == songs && !$0.isLoading }
            .take(1)
            .subscribe(onNext: { _ in expectation.fulfill() })
            .disposed(by: disposeBag)

        reactor.action.onNext(.rankDateType(.weekly))
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(service.requestedRankDates, Array(repeating: .weekly, count: 4))
        XCTAssertEqual(service.requestedRankKeys, ["tj.weekly", "kumyoung.weekly", "dam.weekly", "joysound.weekly"])
    }

    func testRankChartRepositoryReusesCachedChartForSameBrandAndDate() {
        let songs = makeSongs(count: 2)
        let service = StubKaraokeSongSearchService(rankResult: .success(songs))
        let repository = RankChartRepository(service: service)

        repository.chart(brand: .tj, date: .daily)
            .subscribe()
            .disposed(by: disposeBag)
        repository.chart(brand: .tj, date: .daily)
            .subscribe()
            .disposed(by: disposeBag)

        XCTAssertEqual(service.requestedRankKeys, ["tj.daily"])
    }

    func testRankChartRepositoryStoresChartsByBrandAndDateSeparately() {
        let songs = makeSongs(count: 2)
        let service = StubKaraokeSongSearchService(rankResult: .success(songs))
        let repository = RankChartRepository(service: service)

        repository.chart(brand: .tj, date: .daily)
            .subscribe()
            .disposed(by: disposeBag)
        repository.chart(brand: .kumyoung, date: .daily)
            .subscribe()
            .disposed(by: disposeBag)
        repository.chart(brand: .tj, date: .weekly)
            .subscribe()
            .disposed(by: disposeBag)

        XCTAssertEqual(
            service.requestedRankKeys,
            ["tj.daily", "kumyoung.daily", "tj.weekly"]
        )
    }

    func testSearchReactorReturnsSearchFailureAsInlineErrorState() {
        let service = StubKaraokeSongSearchService(searchResult: .failure(NetworkError.internetUnavailable))
        let reactor = SearchResultReactor(service: service)
        let expectation = expectation(description: "검색 실패 상태")

        reactor.state
            .compactMap(\.errorDescription)
            .take(1)
            .subscribe(onNext: { message in
                XCTAssertEqual(message, NetworkError.internetUnavailable.localizedDescription)
                expectation.fulfill()
            })
            .disposed(by: disposeBag)

        reactor.action.onNext(.search("테스트"))
        wait(for: [expectation], timeout: 1.0)
    }

    func testSearchReactorPassesSongObjectToDetailSelection() {
        let songs = makeSongs(count: 6)
        let service = StubKaraokeSongSearchService(searchResult: .success(songs))
        let reactor = SearchResultReactor(service: service)
        let expectation = expectation(description: "선택 곡")

        reactor.state
            .compactMap(\.selectedSong)
            .take(1)
            .subscribe(onNext: { song in
                XCTAssertEqual(song, songs[5])
                expectation.fulfill()
            })
            .disposed(by: disposeBag)

        reactor.action.onNext(.songDetail(songs[5]))
        wait(for: [expectation], timeout: 1.0)
    }

    func testHomePagesKeepLateResponsesWithTheirBrandAndDate() {
        let charts = ControlledRankCharts()
        let reactor = HomeReactor(rankCharts: charts)
        reactor.state.subscribe().disposed(by: disposeBag)
        reactor.action.onNext(.rankDateType(.daily))
        reactor.action.onNext(.brandType(.kumyoung))
        reactor.action.onNext(.rankDateType(.weekly))

        let oldSongs = makeSongs(count: 1)
        charts.succeed(.tj, .daily, songs: oldSongs)
        XCTAssertEqual(reactor.currentState.brandType, .kumyoung)
        XCTAssertEqual(reactor.currentState.dateType, .weekly)
        XCTAssertTrue(reactor.currentState.popularList.isEmpty)
        XCTAssertTrue(reactor.currentState.isLoading)
        XCTAssertEqual(reactor.currentState.charts[RankChartCacheKey(brand: .tj, date: .daily)]?.songs, oldSongs)

        var ky = oldSongs[0]
        ky = Song(brand: .kumyoung, no: ky.no, title: "KY weekly", singer: ky.singer,
                  composer: ky.composer, lyricist: ky.lyricist, release: ky.release)
        charts.succeed(.kumyoung, .weekly, songs: [ky])
        XCTAssertEqual(reactor.currentState.popularList, [ky])
        charts.fail(.kumyoung, .daily)
        XCTAssertEqual(reactor.currentState.popularList, [ky])
        XCTAssertNil(reactor.currentState.errorDescription)
    }

    func testPrefetchWaitsForSelectedChartAndFailureStaysOnOppositePage() {
        let charts = ControlledRankCharts()
        let reactor = HomeReactor(rankCharts: charts)
        reactor.state.subscribe().disposed(by: disposeBag)
        reactor.action.onNext(.rankDateType(.monthly))
        XCTAssertEqual(charts.requests, [RankChartCacheKey(brand: .tj, date: .monthly)])
        let songs = makeSongs(count: 1)
        charts.succeed(.tj, .monthly, songs: songs)
        XCTAssertEqual(charts.requests.count, 2)
        charts.fail(.kumyoung, .monthly)
        XCTAssertEqual(reactor.currentState.popularList, songs)
        XCTAssertNil(reactor.currentState.errorDescription)
        XCTAssertNotNil(reactor.currentState.page(for: .kumyoung).errorDescription)
        XCTAssertFalse(reactor.currentState.page(for: .kumyoung).isLoading)
    }

    func testFavoritePageMutationDoesNotReplaceOtherBrandOrItsError() {
        let reactor = FavoriteSongReactor()
        let songs = makeSongs(count: 2)
        var state = reactor.reduce(state: reactor.initialState, mutation: .favoriteList(.tj, songs))
        state = reactor.reduce(state: state, mutation: .failed(.kumyoung, "KY error"))
        state = reactor.reduce(state: state, mutation: .changeBrand(.kumyoung))
        XCTAssertTrue(state.favoriteSongs.isEmpty)
        XCTAssertEqual(state.errorDescription, "KY error")
        state = reactor.reduce(state: state, mutation: .favoriteList(.tj, [songs[1]]))
        XCTAssertEqual(state.errorDescription, "KY error")
        XCTAssertEqual(state.page(for: .tj).songs, [songs[1]])
        state = reactor.reduce(state: state, mutation: .favoriteList(.kumyoung, []))
        XCTAssertTrue(state.page(for: .kumyoung).hasLoaded)
        XCTAssertNil(state.errorDescription)
        XCTAssertFalse(state.page(for: .kumyoung).isLoading)
    }

    private func makeSongs(count: Int) -> [Song] {
        (0..<count).map { index in
            Song(
                brand: .tj,
                no: "\(index)",
                title: "노래 \(index)",
                singer: "가수 \(index)",
                composer: "작곡가",
                lyricist: "작사가",
                release: "2026"
            )
        }
    }
}

private final class StubKaraokeSongSearchService: KaraokeSongSearching {
    var requestedRankDates: [RankDateType] = []
    var requestedRankKeys: [String] = []
    private let rankResult: Result<[Song], Error>
    private let searchResult: Result<[Song], Error>

    init(
        rankResult: Result<[Song], Error> = .success([]),
        searchResult: Result<[Song], Error> = .success([])
    ) {
        self.rankResult = rankResult
        self.searchResult = searchResult
    }

    func rankSongsRequest(brand: BrandType, date: RankDateType) -> Single<[Song]> {
        requestedRankDates.append(date)
        requestedRankKeys.append("\(brand.rawValue).\(date.cacheIdentifier)")
        return single(from: rankResult)
    }

    func searchSongsRequest(brand: BrandType, query: String, searchType: SearchType) -> Single<[Song]> {
        single(from: searchResult)
    }

    private func single(from result: Result<[Song], Error>) -> Single<[Song]> {
        Single.create { single in
            switch result {
            case let .success(songs):
                single(.success(songs))
            case let .failure(error):
                single(.failure(error))
            }
            return Disposables.create()
        }
    }
}

private final class ControlledRankCharts: RankChartProviding {
    private var subjects: [RankChartCacheKey: PublishSubject<[Song]>] = [:]
    private(set) var requests: [RankChartCacheKey] = []

    func chart(brand: BrandType, date: RankDateType) -> Single<[Song]> {
        let key = RankChartCacheKey(brand: brand, date: date)
        requests.append(key)
        let subject = PublishSubject<[Song]>()
        subjects[key] = subject
        return subject.take(1).asSingle()
    }

    func prefetch(brand: BrandType, date: RankDateType) {}

    func succeed(_ brand: BrandType, _ date: RankDateType, songs: [Song]) {
        subjects[RankChartCacheKey(brand: brand, date: date)]?.onNext(songs)
    }

    func fail(_ brand: BrandType, _ date: RankDateType) {
        subjects[RankChartCacheKey(brand: brand, date: date)]?.onError(NetworkError.internetUnavailable)
    }
}
