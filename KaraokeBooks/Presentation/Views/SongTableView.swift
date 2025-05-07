//
//  SongTableView.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/03/14.
//

import UIKit

final class SongTableView: UITableView {
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        
        if #available(iOS 15.0, *) { //ios15 부터 header padding 적용되어서 간격 넓어짐 제거
            self.sectionHeaderTopPadding = 0
        }
        self.showsVerticalScrollIndicator = false
        self.layer.cornerRadius = 15.0
        self.clipsToBounds = true
        self.backgroundColor = .customBackground
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
