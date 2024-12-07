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
    enum Action {
        
    }
    enum Mutation {
        
    }
    struct State {
        var favoriteSongs: [Song]
        var currentBrand: BrandType
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        
    }
    func reduce(state: State, mutation: Mutation) -> State {
        
    }
}
