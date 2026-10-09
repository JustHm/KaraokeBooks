//
//  BrandType.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/10.
//

import Foundation
/// 노래 검색시 브랜드 설정  (URL에 들어감)
enum BrandType: String, CaseIterable, Codable {
    case tj
    case kumyoung
    case dam
    case joysound
    var name: String {
        switch self {
        case .tj:
            return "TJ"
        case .kumyoung:
            return "KY"
        case .dam:
            return "DAM"
        case .joysound:
            return "JOYSOUND"
        }
    }
    
    static func currentByName(name: String) -> Self? {
        allCases.first { $0.name == name }
    }
}
