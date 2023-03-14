//
//  RankDataType.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/10.
//

import Foundation
/// 인기 순위 노래 검색시 날짜 구분 (URL에 들어감)
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
