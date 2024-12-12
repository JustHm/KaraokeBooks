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
    //case joysound, dam, uga
    var name: String {
        switch self {
        case .tj:
            return "TJ"
        case .kumyoung:
            return "KY"
        }
    }
    
    static func currentByName(name: String) -> Self? {
        switch name {
        case BrandType.tj.name:
            return BrandType.tj
        case BrandType.kumyoung.name:
            return BrandType.kumyoung
        default:
            return nil
        }
    }
}
