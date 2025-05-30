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
    private let service = KaraokeSearchManager.shared
    
    enum Action {
        case brandType(BrandType)
        case rankDateType(String?)
        case songDetail(IndexPath)
    }
    
    enum Mutation {
        case changeBrand(BrandType)
        case changeDate(RankDateType)
        case popularList([Song])
        case LoadState(Bool)
        case moveToDetail(Song?)
        case alertError(NetworkError?)
        case null
    }
    
    struct State {
        var selectedSong: Song?
        var popularList: [Song] = []
        var brandType: BrandType = .tj
        var dateType: RankDateType = .daily
        var isLoading: Bool = false
        var errorDescription: String? = nil
    }
    
    
    func mutate(action: Action) -> Observable<Mutation> { //service 및 데이터 변환
        switch action {
        case let .brandType(brand):
            let changeBrand: Observable<Mutation> = .just(Mutation.changeBrand(brand))
            let changestate: Observable<Mutation> = .just(Mutation.LoadState(true))
            let response: Observable<Mutation> = service.rx.rankSongsRequest(brand: brand, date: currentState.dateType)
                .asObservable().materialize() //Event<>로 감싸주는것
                .map { result -> Mutation in
                    switch result {
                    case .completed: return .null
                    case let .next(songs): return .popularList(songs)
                    case let .error(error): return .alertError(error as? NetworkError)
                    }
                }
            return .concat([changeBrand, changestate, response])
        case let .rankDateType(date):
            let date = (RankDateType(rawValue: date ?? "일간") ?? RankDateType.daily)
            let response: Observable<Mutation> = service.rx.rankSongsRequest(brand: currentState.brandType, date: date)
                .asObservable().materialize()
                .map { result -> Mutation in
                    switch result {
                    case .completed: return .null
                    case let .next(songs): return .popularList(songs)
                    case let .error(error): return .alertError(error as? NetworkError)
                    }
                }
            return .concat([
                .just(.changeDate(date)), .just(.LoadState(true)),
                response
            ])
        case let .songDetail(indexPath):
            let song = currentState.popularList[indexPath.row]
            return .concat([.just(.moveToDetail(song)), .just(.moveToDetail(nil))])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State { // state data 주입
        var state = state
        switch mutation {
        case let .moveToDetail(song):
            state.selectedSong = song
        case let .LoadState(isLoading):
            state.isLoading = isLoading
        case let .changeDate(date):
            state.dateType = date
        case let .changeBrand(brand):
            state.brandType = brand
        case let .popularList(songs):
            state.popularList = songs
            state.isLoading = false
        case let .alertError(error):
            if let error {
                state.errorDescription = error.errorDescription
            }
            else { state.errorDescription = nil }
        case .null: break
        }
        return state
    }
    
    func reactorForSetting(song: Song) -> SongDetailReactor? {
        return SongDetailReactor(song: song)
    }
}
