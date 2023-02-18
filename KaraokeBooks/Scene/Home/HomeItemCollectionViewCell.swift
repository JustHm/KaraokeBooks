//
//  HomeItemCollectionViewCell.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/09.
//

import UIKit

final class HomeItemCollectionViewCell: UICollectionViewCell {
    static let identifier = "HomeItemCollectionViewCell"
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15.0, weight: .bold)
        label.textColor = .customPrimaryText
        return label
    }()
    
    func setup(title: String) {
        titleLabel.text = title
        setupLayout()
    }
}

private extension HomeItemCollectionViewCell {
    func setupLayout() {
        contentView.layer.cornerRadius = 15.0
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowRadius = 4.0
        contentView.backgroundColor = .customForeground2
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}
