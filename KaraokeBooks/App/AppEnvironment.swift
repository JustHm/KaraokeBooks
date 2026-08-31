//
//  AppEnvironment.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/08/31.
//

import Foundation

enum AppEnvironment {
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-uiTesting")
    }

    static func makeKaraokeSearchService() -> KaraokeSongSearching {
        #if DEBUG
        return isUITesting ? UITestingKaraokeSearchService() : KaraokeSearchManager.shared
        #else
        return KaraokeSearchManager.shared
        #endif
    }
}
