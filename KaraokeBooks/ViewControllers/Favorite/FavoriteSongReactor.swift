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
//        case songDetail(IndexPath)
    }
    enum Mutation {
        case favoriteList(Result<[Song], PersistenceError>)
        case changeBrand(BrandType)
        case alertError(PersistenceError?)
    }
    struct State {
        var favoriteSongs: [Song] = []
        var currentBrand: BrandType = .tj
        var isEmpty = true
        var errorDescription: String? = nil
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .brandType(brand):
            return persistence.rx.fetchFavoriteSongs(brand: initialState.currentBrand.rawValue)
                .asObservable()
                .materialize()
                .map { event -> Event<Result<[Song], PersistenceError>> in
                    switch event {
                    case .completed: return .completed
                    case let .next(songs): return .next(Result.success(songs))
                    case let .error(error): return .next(Result.failure(error as! PersistenceError))
                    }
                }
                .dematerialize()
                .map{Mutation.favoriteList($0)}
        case let .deleteSong(indexPath):
            let song = initialState.favoriteSongs[indexPath.row]
            return persistence.rx.deleteSong(songID: song.id)
                .asObservable()
                .materialize()
                .map { event -> FavoriteSongReactor.Mutation in
                    switch event {
                    case .completed: return Mutation.alertError(nil)
                    case .next(_): return Mutation.alertError(nil)
                    case let .error(error): return Mutation.alertError(error as? PersistenceError)
                    }
                }
//        case let .songDetail(indexPath): break
        }
    }
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .favoriteList(result):
            switch result {
            case let .success(songs): state.favoriteSongs = songs
            case let .failure(error): state.errorDescription = error.localizedDescription
            }
        case let .changeBrand(brand):
            state.currentBrand = brand
        case let .alertError(error):
            if let error {
                state.errorDescription = error.localizedDescription
            }
        }
        return state
    }
}
