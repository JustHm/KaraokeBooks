//
//  HomeReactor.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 11/8/24.
//
import Foundation
import ReactorKit

class HomeReactor: Reactor {
    var initialState = State()
    private var searchManager = KaraokeSearchManager()
    
    enum Action {
        case brandType(BrandType)
        case rankDateType(String?)
        case songDetail(IndexPath)
    }
    
    enum Mutation {
        case popularList([Song])
        case LoadState(Bool)
        case changeBrand(BrandType)
        case changeDate(RankDateType)
    }
    
    struct State {
        var popularList: [Song] = [Song(brand: .kumyoung, no: "HI2", title: "HI1", singer: "HI1", composer: "HI1", lyricist: "HI1", release: "HI1")]
        var brandType: BrandType?
        var dateType: RankDateType?
        var isLoading: Bool = false
    }
    
    
    func mutate(action: Action) -> Observable<Mutation> { //service 및 데이터 변환
        switch action {
        case let .brandType(brand):
            return .concat([
                .just(.changeBrand(brand)), .just(.LoadState(true)),
                .just(.popularList([
                    Song(brand: .kumyoung, no: "HI1", title: "HI1", singer: "HI1", composer: "HI1", lyricist: "HI1", release: "HI1"),
                    Song(brand: .kumyoung, no: "HI2", title: "HI1", singer: "HI1", composer: "HI1", lyricist: "HI1", release: "HI1")
                ]))
            ])
        case let .rankDateType(date):
            let date = (RankDateType(rawValue: date ?? "일간") ?? RankDateType.daily)
            return .concat([
                .just(.changeDate(date)), .just(.LoadState(true)),
                .just(.popularList([
                    Song(brand: .kumyoung, no: "HI2", title: "HI1", singer: "HI1", composer: "HI1", lyricist: "HI1", release: "HI1"),
                    Song(brand: .kumyoung, no: "HI1", title: "HI1", singer: "HI1", composer: "HI1", lyricist: "HI1", release: "HI1")
                ]))
            ])
        case let .songDetail(indexPath):
            return .just(.popularList([]))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State { // state data 주입
        var state = state
        switch mutation {
        case let .LoadState(isLoad):
            state.isLoading = isLoad
        case let .changeDate(date):
            state.dateType = date
        case let .changeBrand(brand):
            state.brandType = brand
        case let .popularList(songs):
            state.popularList = songs
            state.isLoading = false
        }
        return state
    }
    
    
}
