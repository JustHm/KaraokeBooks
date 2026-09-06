//
//  SongInfoStackView.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/10.
//

import SwiftUI

struct SongInfoStackView: View {
    let song: Song

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(song.title)
                .font(.title2.weight(.bold))
                .foregroundColor(Color(uiColor: .customPrimaryText ?? .label))
                .fixedSize(horizontal: false, vertical: true)
            Text(song.singer)
                .font(.subheadline)
                .foregroundColor(Color(uiColor: .customSecondaryText ?? .secondaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
