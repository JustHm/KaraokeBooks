//
//  FavoriteRouletteReactor.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 9/6/26.
//
import ReactorKit


final class FavoriteRouletteReactor: Reactor {
    enum Action { case draw }
    struct State {
        var drawRevision = 0
        var song: Song?
        var songs: [Song]
        var remaining: [Song]
    }
    enum Mutation {
        case draw
        case refresh([Song])
    }
    let initialState: State
    private let persistence: PersistenceManager

    init(songs: [Song], persistence: PersistenceManager = .shared) {
        self.persistence = persistence
        var seen = Set<String>()
        let uniqueSongs = songs.filter { seen.insert($0.id).inserted }
        initialState = State(songs: uniqueSongs, remaining: uniqueSongs)
    }

    func mutate(action: Action) -> Observable<Mutation> { .just(.draw) }

    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        guard let brand = initialState.songs.first?.brand else { return mutation }
        let updates = persistence.event.flatMapLatest { [persistence] _ in
            persistence.rx.fetchFavoriteSongs(brand: brand.name).asObservable()
                .map(Mutation.refresh)
                .catch { _ in .empty() }
        }
        return .merge(mutation, updates)
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case .draw:
            if state.remaining.isEmpty { state.remaining = state.songs }
            guard !state.remaining.isEmpty else { return state }
            state.song = state.remaining.remove(at: Int.random(in: state.remaining.indices))
            state.drawRevision += 1
        case let .refresh(songs):
            let oldIDs = Set(state.songs.map(\.id))
            let remainingIDs = Set(state.remaining.map(\.id))
            var seen = Set<String>()
            state.songs = songs.filter { seen.insert($0.id).inserted }
            state.remaining = state.songs.filter { remainingIDs.contains($0.id) || !oldIDs.contains($0.id) }
            if let selected = state.song {
                state.song = state.songs.first { $0.id == selected.id }
            }
        }
        return state
    }
}
