//
//  SongDetailReactor.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 12/7/24.
//

import Foundation
import ReactorKit

final class SongDetailReactor: Reactor {
    var initialState: State = State()
//    var url: URL? {
//        get {
//            guard let song = currentState.song else { return nil }
//            switch song.brand {
//            case .kumyoung:
//                return URL(string: "https://m.youtube.com/@KARAOKEKY/search?query=\(song.no)")
//            case .tj:
//                return URL(string: "https://m.youtube.com/user/ziller/search?query=\(song.no)")
//            }
//        }
//    }
    enum Action {
//        case starTapped
//        case youtubeTapped
//        case closeTapped
    }
    enum Mutation {
//        case changeStar
//        case moveToYoutube
//        case close
    }
    struct State {
//        var youtubeURL: URL?
//        var isStar: Bool = false
//        var song: Song?
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        
    }
}
