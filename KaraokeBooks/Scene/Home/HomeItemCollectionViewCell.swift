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
        label.font = .systemFont(ofSize: 16.0, weight: .bold)
        label.textColor = .white
        return label
    }()
    private lazy var gradientLayer = CAGradientLayer()
    
    func setup(title: String) {
        titleLabel.text = title
        setupLayout()
    }
}

private extension HomeItemCollectionViewCell {
    func setupLayout() {
        setupGradientLayer()
        contentView.layer.addSublayer(gradientLayer)
        contentView.layer.cornerRadius = 15.0
        contentView.clipsToBounds = true
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    func setupGradientLayer() {
        gradientLayer.frame = contentView.frame
        let colors: [CGColor] = [
            .init(red: 1.00, green: 0.25, blue: 0.42, alpha: 1.00),
            .init(red: 1.00, green: 0.29, blue: 0.17, alpha: 1.00)
        ]
        gradientLayer.colors = colors
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
    }
}
