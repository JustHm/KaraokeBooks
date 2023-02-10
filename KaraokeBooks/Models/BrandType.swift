//
//  BrandType.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/10.
//

import Foundation

enum BrandType: String, CaseIterable, Codable {
    case tj
    case kumyoung
    //case joysound
    //case dam
    //case uga
    
    var replace: String {
        switch self {
        case .tj:
            return "TJ"
        case .kumyoung:
            return "KY"
        }
    }
}
