//
//  RankDataType.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/10.
//

import Foundation
/// 인기 순위 노래 검색시 날짜 구분 (URL에 들어감)
enum RankDateType: CaseIterable, Hashable {
    case daily
    case weekly
    case monthly

    var localizedTitle: String {
        switch self {
        case .daily:
            return String(localized: "chart.daily")
        case .weekly:
            return String(localized: "chart.weekly")
        case .monthly:
            return String(localized: "chart.monthly")
        }
    }

    var replace: String {
        switch self {
        case .daily:
            return "daily"
        case .weekly:
            return "weekly"
        case .monthly:
            return "monthly"
        }
    }

    var cacheIdentifier: String {
        replace
    }
}
