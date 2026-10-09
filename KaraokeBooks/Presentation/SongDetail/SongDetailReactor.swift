//
//  SongDetailReactor.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 12/7/24.
//

import Foundation
import ReactorKit

final class SongDetailReactor: Reactor {
    private let persistence: PersistenceManager
    var initialState: State
    private var youtube: URL? {
        get {
            let song = currentState.song
            let path: String
            switch song.brand {
            case .kumyoung:
                path = "/@KARAOKEKY/search"
            case .tj:
                path = "/user/ziller/search"
            case .dam, .joysound:
                path = "/results"
            }

            var components = URLComponents()
            components.scheme = "https"
            components.host = "www.youtube.com"
            components.path = path
            switch song.brand {
            case .tj, .kumyoung:
                components.queryItems = [URLQueryItem(name: "query", value: song.no)]
            case .dam, .joysound:
                components.queryItems = [
                    URLQueryItem(name: "search_query", value: "\(song.title) \(song.singer) カラオケ")
                ]
            }
            return components.url
        }
    }
    enum Action {
        case saveMemo(String)
        case viewDidLoad
        case starTapped
        case youtubeTapped
    }
    enum Mutation {
        case memoLoaded(String?)
        case memoSaved(String?)
        case changeStar(Bool)
        case moveToYoutube(URL?)
        case alertError(String?)
    }
    struct State {
        @Pulse var youtubeURL: URL?
        var isStar: Bool = false
        var memo: String?
        var memoSaveRevision = 0
        var song: Song
        @Pulse var errorMessage: String?
    }
    init(song: Song, persistence: PersistenceManager = .shared) {
        self.persistence = persistence
        self.initialState = State(song: song)
    }
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .saveMemo(text):
            do {
                try persistence.saveMemo(text, songID: currentState.song.id)
                return .just(.memoSaved(try persistence.memo(songID: currentState.song.id)))
            } catch { return .just(.alertError(error.localizedDescription)) }
        case .starTapped:
            var result: Observable<Event<Bool>>
            if currentState.isStar {
                result = persistence.rx.deleteSong(songID: currentState.song.id)
                    .asObservable().materialize()
            }
            else {
                result = persistence.rx.addFavoriteSong(song: currentState.song)
                    .asObservable().materialize()
            }
            return result.withUnretained(self)
                .map { owner, result -> SongDetailReactor.Mutation in
                    let star = !owner.currentState.isStar
                    switch result {
                    case .next:
                        return Mutation.changeStar(star)
                    case let .error(error):
                        let errorMessage = (error as? PersistenceError)?.errorDescription
                        return Mutation.alertError(errorMessage)
                    case .completed:
                        return Mutation.alertError(nil)
                    }
                }
        case .youtubeTapped:
            return .just(Mutation.moveToYoutube(youtube))
        case .viewDidLoad:
            let isStar = persistence.rx.checkExistSong(songID: currentState.song.id)
                .asObservable().materialize()
                .map { result -> SongDetailReactor.Mutation in
                    switch result {
                    case let .next(isStar):
                        return Mutation.changeStar(isStar)
                    case let .error(error):
                        let errorMessage = (error as? PersistenceError)?.errorDescription
                        return Mutation.alertError(errorMessage)
                    case .completed:
                        return Mutation.alertError(nil)
                    }
                }
            let memo: Observable<Mutation> = .deferred { [self] in
                do { return .just(.memoLoaded(try persistence.memo(songID: currentState.song.id))) }
                catch { return .just(.alertError(error.localizedDescription)) }
            }
            return .concat(isStar, memo)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .memoLoaded(memo): state.memo = memo
        case let .memoSaved(memo):
            state.memo = memo
            state.memoSaveRevision += 1
        case let .changeStar(isStar):
            state.isStar = isStar
            if !isStar { state.memo = nil }
        case let .moveToYoutube(url):
            state.youtubeURL = url
        case let .alertError(msg):
            state.errorMessage = msg
        }
        return state
    }
}
