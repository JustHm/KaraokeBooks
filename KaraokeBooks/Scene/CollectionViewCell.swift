//
//  CollectionViewCell.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/09.
//

import UIKit

final class CollectionViewCell: UICollectionViewCell {
    static let identifier = "CollectionViewCell"
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "HELLO"
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 15.0, weight: .bold)
        return label
    }()
    
    func setup(title: String) {
        titleLabel.text = title
        setupLayout()
    }
}

private extension CollectionViewCell {
    func setupLayout() {
        layer.cornerRadius = 12
        backgroundColor = .lightGray
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}
