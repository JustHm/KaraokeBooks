//
//  HomeReactor.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 11/8/24.
//
import Foundation
import ReactorKit

class HomeReactor: Reactor {
    var initialState = State()
    private let rankCharts: RankChartProviding

    init(
        service: KaraokeSongSearching = AppEnvironment.makeKaraokeSearchService(),
        rankCharts: RankChartProviding? = nil
    ) {
        self.rankCharts = rankCharts ?? RankChartRepository(service: service)
    }

    enum Action {
        case brandType(BrandType)
        case rankDateType(RankDateType)
        case songDetail(Song)
    }

    enum Mutation {
        case changeBrand(BrandType)
        case changeDate(RankDateType)
        case loading(RankChartCacheKey)
        case loaded(RankChartCacheKey, [Song])
        case failed(RankChartCacheKey, String)
        case moveToDetail(Song?)
    }

    struct State {
        var selectedSong: Song?
        var brandType: BrandType = .tj
        var dateType: RankDateType = .daily
        var charts: [RankChartCacheKey: SongListPageState] = [:]

        func page(for brand: BrandType) -> SongListPageState {
            charts[RankChartCacheKey(brand: brand, date: dateType)] ?? SongListPageState()
        }

        var popularList: [Song] { page(for: brandType).songs }
        var isLoading: Bool { page(for: brandType).isLoading }
        var errorDescription: String? { page(for: brandType).errorDescription }
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .brandType(brand):
            return .concat(.just(.changeBrand(brand)), loadCharts(brand: brand, date: currentState.dateType))
        case let .rankDateType(date):
            return .concat(.just(.changeDate(date)), loadCharts(brand: currentState.brandType, date: date))
        case let .songDetail(song):
            return .concat(.just(.moveToDetail(song)), .just(.moveToDetail(nil)))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .changeBrand(brand): state.brandType = brand
        case let .changeDate(date): state.dateType = date
        case let .moveToDetail(song): state.selectedSong = song
        case let .loading(key):
            var page = state.charts[key] ?? SongListPageState()
            page.isLoading = true
            page.errorDescription = nil
            state.charts[key] = page
        case let .loaded(key, songs):
            state.charts[key] = SongListPageState(songs: songs, hasLoaded: true)
        case let .failed(key, message):
            var page = state.charts[key] ?? SongListPageState()
            page.isLoading = false
            page.errorDescription = message
            state.charts[key] = page
        }
        return state
    }

    func reactorForSetting(song: Song) -> SongDetailReactor? {
        SongDetailReactor(song: song)
    }

    private func loadCharts(brand: BrandType, date: RankDateType) -> Observable<Mutation> {
        let brands = [brand] + BrandType.allCases.filter { $0 != brand }
        // Load the visible chart first, then warm the other brand pages.
        return Observable.concat(brands.map { loadChart(brand: $0, date: date) })
    }

    private func loadChart(brand: BrandType, date: RankDateType) -> Observable<Mutation> {
        Observable.deferred { [weak self] in
            guard let self else { return .empty() }
            let key = RankChartCacheKey(brand: brand, date: date)
            if let page = self.currentState.charts[key], page.hasLoaded || page.isLoading {
                return .empty()
            }
            return .concat(
                .just(.loading(key)),
                self.rankCharts.chart(brand: brand, date: date).asObservable()
                    .map { .loaded(key, $0) }
                    .catch { .just(.failed(key, $0.localizedDescription)) }
            )
        }
    }
}
