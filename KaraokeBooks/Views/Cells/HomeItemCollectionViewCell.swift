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
    private lazy var titleIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    private lazy var gradientLayer = CAGradientLayer()
    
    func setup(title: HomeList) {
        titleLabel.text = title.rawValue
        titleIcon.image = title == .favourite ? UIImage(systemName: "star") : UIImage(systemName: "magnifyingglass")
        setupLayout()
    }
}

private extension HomeItemCollectionViewCell {
    func setupLayout() {
        setupGradientLayer()
        let stack = UIStackView(arrangedSubviews: [titleIcon, titleLabel])
        stack.axis = .vertical
        stack.spacing = 8
        
        contentView.layer.addSublayer(gradientLayer)
        contentView.layer.cornerRadius = 15.0
        contentView.clipsToBounds = true
        addSubview(stack)
        stack.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    func setupGradientLayer() {
        gradientLayer.frame = contentView.frame
        let colors: [CGColor] = [
            .init(red: 0.84, green: 0.05, blue: 0.33, alpha: 1.00), //#D60C55
            .init(red: 0.71, green: 0.17, blue: 0.48, alpha: 1.00) //#B42B7B
            //.init(red: 0.52, green: 0.26, blue: 0.55, alpha: 1.00)  //#84438D
        ]
        gradientLayer.colors = colors
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
    }
}

