//
//  SearchResultReactor.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 12/17/24.
//

import Foundation
import ReactorKit

final class SearchResultReactor: Reactor {
    var initialState = State()
    private let service = KaraokeSearchManager.shared
    enum Action {
        case searchQuery(String?)
        case songDetail(IndexPath)
        case brandType(BrandType)
        case searchType(SearchScopeType)
        case currentRow(IndexPath)
        case search
        case clear
    }
    enum Mutation {
        case changeBrand(BrandType)
        case changeSearchType(SearchType)
        case changeQuery(String?)
        case songDetail(Song?)
        case searchSongs([Song], reload: Bool)
        case alertError(NetworkError?)
        case clear
    }
    struct State {
        var songs: [Song] = []
        var selectedSong: Song?
        var errorDescription: String?
        var isEmpty: Bool = true
        
        var searchQuery: String?
        var brandType: BrandType = .tj
        var searchType: SearchType = .title
        var currentPage: Int = 0
        var currentRow: Int = 0
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .search:
            guard let query = currentState.searchQuery else {
                return .just(.alertError(nil))
            }
            let brand = currentState.brandType
            let searchType = currentState.searchType
            let page = currentState.currentPage
            return searchSongsByQuery(brand: brand, type: searchType, query: query, page: page, reload: true)
        case let .currentRow(indexPath):
            guard let query = currentState.searchQuery,
                  indexPath.row > currentState.songs.count - 2
            else { return .just(.alertError(nil)) }
            let brand = currentState.brandType
            let searchType = currentState.searchType
            let page = currentState.currentPage
            return searchSongsByQuery(brand: brand, type: searchType, query: query, page: page, reload: false)
        case let .brandType(brand):
            return .just(.changeBrand(brand))
        case let .searchType(type):
            switch type {
            case .title: return .just(.changeSearchType(.title))
            case .singer: return .just(.changeSearchType(.singer))
            }
        case let .songDetail(indexPath):
            let song = currentState.songs[indexPath.row]
            return .concat([.just(.songDetail(song)), .just(.songDetail(nil))])
        case .clear:
            return .just(.clear)
        case let .searchQuery(query):
            return .just(.changeQuery(query))
        }
    }
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .changeQuery(query):
            state.searchQuery = query
            state.currentPage = 0
        case let .changeBrand(brand):
            state.brandType = brand
            state.currentPage = 0
        case let .changeSearchType(type):
            state.searchType = type
            state.currentPage = 0
        case let .songDetail(song):
            state.selectedSong = song
        case let .searchSongs(songs, reload):
            if reload { state.songs = songs }
            else { state.songs += songs }
            state.isEmpty = !state.songs.isEmpty
            state.currentPage += 1
        case .clear:
            state.searchQuery = nil
        case let .alertError(error):
            if let error {
                state.errorDescription = error.localizedDescription
            }
        }
        return state
    }
    func reactorForSetting(song: Song) -> SongDetailReactor? {
        return SongDetailReactor(song: song)
    }
    
    private func searchSongsByQuery(brand: BrandType,
                                    type: SearchType,
                                    query: String,
                                    page: Int,
                                    reload: Bool
    ) -> Observable<Mutation> {
        return service.rx.searchReqeust(brand: brand, searchType: type, query: query, page: page)
            .asObservable()
            .materialize()
            .map { event -> Mutation in
                switch event {
                case .completed:
                    return .alertError(nil)
                case let .error(error):
                    return .alertError(error as? NetworkError)
                case let .next(songs):
                    return .searchSongs(songs, reload: reload)
                }
            }
    }
}
