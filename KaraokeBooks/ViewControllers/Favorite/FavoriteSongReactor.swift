//
//  FavoriteSongReactor.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 12/7/24.
//

import Foundation
import ReactorKit

final class FavoriteSongReactor: Reactor {
    var initialState: State = State()
    private let persistence = PersistenceManager.shared
    enum Action {
        case brandType(BrandType)
        case deleteSong(IndexPath)
        case songDetail(IndexPath)
        case reload
    }
    enum Mutation {
        case favoriteList([Song])
        case changeBrand(BrandType)
        case alertError(PersistenceError?)
        case deleted(IndexPath)
        case selected(Song?)
    }
    struct State {
        var favoriteSongs: [Song] = []
        var selectedSong: Song?
        var currentBrand: BrandType = .tj
        var isEmpty = true
        var errorDescription: String? = nil
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .brandType(brand):
            let result = persistence.rx.fetchFavoriteSongs(brand: brand.name)
                .asObservable()
                .materialize()
                .map { event -> FavoriteSongReactor.Mutation in
                    switch event {
                    case .completed: return .alertError(nil)
                    case let .next(songs):
                        return .favoriteList(songs)
                    case let .error(error): return .alertError(error as? PersistenceError)
                    }
                }
            return .concat([result, .just(.changeBrand(brand))])
        case let .deleteSong(indexPath):
            let song = currentState.favoriteSongs[indexPath.row]
            return persistence.rx.deleteSong(songID: song.id)
                .asObservable()
                .materialize()
                .map { event -> FavoriteSongReactor.Mutation in
                    switch event {
                    case .completed: return Mutation.alertError(nil)
                    case .next(_): return Mutation.deleted(indexPath)
                    case let .error(error): return Mutation.alertError(error as? PersistenceError)
                    }
                }
        case .reload:
            let brand = currentState.currentBrand.name
            return persistence.rx.fetchFavoriteSongs(brand: brand)
                .asObservable()
                .materialize()
                .map { event -> FavoriteSongReactor.Mutation in
                    switch event {
                    case .completed: return .alertError(nil)
                    case let .next(songs):
                        return .favoriteList(songs)
                    case let .error(error): return .alertError(error as? PersistenceError)
                    }
                }
        case let .songDetail(indexPath):
            let song = currentState.favoriteSongs[indexPath.row]
            return .concat([.just(.selected(song)), .just(.selected(nil))])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .favoriteList(songs):
            state.favoriteSongs = songs
            state.isEmpty = songs.isEmpty
        case let .changeBrand(brand):
            state.currentBrand = brand
        case let .selected(song):
            state.selectedSong = song
        case let .alertError(error):
            if let error {
                state.errorDescription = error.localizedDescription
            }
        case let .deleted(indexPath):
            state.favoriteSongs.remove(at: indexPath.row)
        }
        return state
    }
    
    func transform(action: Observable<Action>) -> Observable<Action> {
        let eventAction =  persistence.event.flatMap { event -> Observable<Action> in
            switch event {
            case let .deleted(isDeleted):
                if isDeleted { return .just(.reload)}
                else { return .just(.reload)}
            }
        }
        return Observable.merge(action, eventAction)
    }
    
    // FavoriteSongReactor에서 SongDetailReactor를 return해 주어야 값 처리가 가능함.
    func reactorForSetting() -> SongDetailReactor? {
        guard let song = currentState.selectedSong else { return nil }
        return SongDetailReactor(song: song)
    }
}
