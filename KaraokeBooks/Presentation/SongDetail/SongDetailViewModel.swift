//
//  SongDetailViewModel.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/09/06.
//

import SwiftUI

final class SongDetailViewModel: ObservableObject {
    @Published var state: SongDetailReactor.State

    init(state: SongDetailReactor.State) { self.state = state }
}
