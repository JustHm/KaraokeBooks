//
//  SongDetailReactor.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 12/7/24.
//

import Foundation
import ReactorKit

final class SongDetailReactor: Reactor {
    private let persistence = PersistenceManager.shared
    var initialState: State
    private var youtube: URL? {
        get {
            let song = currentState.song
            switch song.brand {
            case .kumyoung:
                return URL(string: "https://m.youtube.com/@KARAOKEKY/search?query=\(song.no)")
            case .tj:
                return URL(string: "https://m.youtube.com/user/ziller/search?query=\(song.no)")
            }
        }
    }
    enum Action {
        case viewDidLoad
        case starTapped
        case youtubeTapped
        case closeTapped
    }
    enum Mutation {
        case changeStar(Bool)
        case moveToYoutube(URL?)
        case close
        case alertError(String?)
    }
    struct State {
        var youtubeURL: URL?
        var isStar: Bool = false
        var song: Song
        var errorMessage: String?
        var isDismiss = false
    }
    init(song: Song) {
        self.initialState = State(song: song)
    }
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
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
        case .closeTapped:
            return .just(Mutation.close)
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
            return isStar
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .changeStar(isStar):
            state.isStar = isStar
        case .close:
            state.isDismiss = true
        case let .moveToYoutube(url):
            state.youtubeURL = url
        case let .alertError(msg):
            state.errorMessage = msg
        }
        return state
    }
}
