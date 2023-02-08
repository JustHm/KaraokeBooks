//
//  RankTableViewFooter.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import UIKit
import SnapKit

final class RankTableViewFooter: UITableViewHeaderFooterView {
    static let identifier = "RankTableViewFooter"
    private lazy var detailButton: UIButton = {
        let button = UIButton()
        button.setTitle("자세히보기 →", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12.0)
        button.setTitleColor(.tintColor, for: .normal)
        return button
    }()
    
    func setup() {
        addSubview(detailButton)
        detailButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().inset(16.0)
        }
        
    }
}
