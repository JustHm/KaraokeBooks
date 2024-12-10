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
    var initialState: State = State()
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
        case starTapped
        case youtubeTapped
        case closeTapped
    }
    enum Mutation {
        case changeStar
        case moveToYoutube(URL?)
        case close
        case alertError(String?)
    }
    struct State {
        var youtubeURL: URL?
        var isStar: Bool = false
        var song: Song = Song(brand: .kumyoung, no: "1", title: "1", singer: "1", composer: "1", lyricist: "1", release: "1")
        var errorMessage: String?
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .starTapped:
            return persistence.rx.deleteSong(songID: currentState.song.id)
                .asObservable().materialize()
                .map { result -> SongDetailReactor.Mutation in
                    switch result {
                    case let .next(done):
                        return Mutation.changeStar
                    case let .error(error):
                        let errorMessage = (error as? PersistenceError)?.errorDescription
                        return Mutation.alertError(errorMessage)
                    case .completed:
                        return Mutation.alertError(nil)
                    }
                }
        case .youtubeTapped:
            if let url = youtube {
                return .just(Mutation.moveToYoutube(youtube))
            }
            else {
                return .just(.alertError("곡 번호를 확인할 수 없습니다."))
            }
        case .closeTapped:
            return .just(Mutation.close)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case .changeStar:
            state.isStar = !state.isStar
        case .close: break
        case let .moveToYoutube(url):
            state.youtubeURL = url
        case let .alertError(msg):
            state.errorMessage = msg
        }
        return state
    }
}
