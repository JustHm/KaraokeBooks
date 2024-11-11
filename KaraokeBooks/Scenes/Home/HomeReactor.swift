//
//  HomeReactor.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 11/8/24.
//

import ReactorKit

class HomeReactor: Reactor {
    var initialState = State()
    
    enum Action {
        case brandType(BrandType)
        case popularRanking(RankDateType)
    }
    
    enum Mutation {
        case popularList([Song])
        case LoadState(Bool)
        case changeBrand(BrandType)
    }
    
    struct State {
        var popularList: [Song] = []
        var brandType: BrandType?
        var isLoading: Bool = false
    }
    
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .popularRanking(randData):
            return Observable.just(.popularList([]))
        case let .brandType(brand):
            return Observable.just(.changeBrand(brand))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .LoadState(isLoad):
            state.isLoading = isLoad
        case let .changeBrand(brand):
            state.brandType = brand
        case let .popularList(songs):
            state.popularList = songs
        }
        return state
    }
    
    
}
