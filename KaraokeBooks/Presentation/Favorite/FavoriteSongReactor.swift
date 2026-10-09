//
//  FavoriteSongReactor.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 12/7/24.
//

import Foundation
import ReactorKit

final class FavoriteSongReactor: Reactor {
    var initialState = State()
    private let persistence = PersistenceManager.shared

    enum Action {
        case brandType(BrandType)
        case deleteSong(Song)
        case deleteSongs([Song])
        case songDetail(Song)
        case reload
    }

    enum Mutation {
        case loading(BrandType)
        case favoriteList(BrandType, [Song])
        case changeBrand(BrandType)
        case failed(BrandType, String)
        case selected(Song?)
    }

    struct State {
        var pages: [BrandType: SongListPageState] = [:]
        var selectedSong: Song?
        var currentBrand: BrandType = .tj

        func page(for brand: BrandType) -> SongListPageState {
            pages[brand] ?? SongListPageState()
        }

        var favoriteSongs: [Song] { page(for: currentBrand).songs }
        var isEmpty: Bool { favoriteSongs.isEmpty }
        var errorDescription: String? { page(for: currentBrand).errorDescription }
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .brandType(brand):
            return .concat(.just(.changeBrand(brand)), loadPages(startingWith: brand))
        case let .deleteSong(song):
            return persistence.rx.deleteSong(songID: song.id).asObservable()
                .flatMap { _ -> Observable<Mutation> in .empty() }
                .catch { .just(.failed(song.brand, $0.localizedDescription)) }
        case let .deleteSongs(songs):
            return persistence.rx.deleteSongs(songIDs: songs.map(\.id)).asObservable()
                .flatMap { _ -> Observable<Mutation> in .empty() }
                .catch { .just(.failed(self.currentState.currentBrand, $0.localizedDescription)) }
        case .reload:
            return loadPages(startingWith: currentState.currentBrand)
        case let .songDetail(song):
            return .concat(.just(.selected(song)), .just(.selected(nil)))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .favoriteList(brand, songs):
            state.pages[brand] = SongListPageState(songs: songs, hasLoaded: true)
        case let .changeBrand(brand): state.currentBrand = brand
        case let .selected(song): state.selectedSong = song
        case let .loading(brand):
            var page = state.page(for: brand)
            page.isLoading = true
            page.errorDescription = nil
            state.pages[brand] = page
        case let .failed(brand, message):
            var page = state.page(for: brand)
            page.isLoading = false
            page.errorDescription = message
            state.pages[brand] = page
        }
        return state
    }

    func transform(action: Observable<Action>) -> Observable<Action> {
        // Core Data emits deletion while the delete action is still being handled.
        // Queue the reload so ReactorKit receives non-overlapping action events.
        let eventAction = persistence.event.observe(on: MainScheduler.asyncInstance)
            .flatMap { event -> Observable<Action> in
                switch event {
                case let .deleted(isDeleted): return isDeleted ? .just(.reload) : .empty()
                }
            }
        return Observable.merge(action, eventAction)
    }

    func reactorForSetting() -> SongDetailReactor? {
        guard let song = currentState.selectedSong else { return nil }
        return SongDetailReactor(song: song)
    }

    private func loadPages(startingWith brand: BrandType) -> Observable<Mutation> {
        let brands = [brand] + BrandType.allCases.filter { $0 != brand }
        return Observable.concat(brands.map { loadPage($0) })
    }

    private func loadPage(_ brand: BrandType) -> Observable<Mutation> {
        .concat(
            .just(.loading(brand)),
            persistence.rx.fetchFavoriteSongs(brand: brand.name).asObservable()
                .map { .favoriteList(brand, $0) }
                .catch { .just(.failed(brand, $0.localizedDescription)) }
        )
    }
}
