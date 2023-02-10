//
//  RankDataType.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/10.
//

import Foundation

enum RankDateType: String, CaseIterable {
    case daily, weekly, monthly
    var replace: String {
        switch self {
        case .daily:
            return "일간"
        case .weekly:
            return "주간"
        case .monthly:
            return "월간"
        }
    }
}
