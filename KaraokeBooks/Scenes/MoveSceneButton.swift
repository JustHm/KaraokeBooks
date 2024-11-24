//
//  MoveSceneButton.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 11/21/24.
//

import UIKit

final class MoveSceneButton: UIButton {
    private lazy var gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(title: String, symbol: String) { // star, magnifyingglass
        super.init(frame: .zero)
        setupGradientLayer()
        self.tintColor = .black
        setTitle(title, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16.0, weight: .bold)
        setImage(UIImage(systemName: symbol)?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
//        layer.insertSublayer(gradientLayer, at: 0)
//        layer.addSublayer(gradientLayer)
        backgroundColor = .init(red: 0.84, green: 0.05, blue: 0.33, alpha: 1.00) //#D60C55
        layer.cornerRadius = 15.0
        self.clipsToBounds = true
        
    }
    func setupGradientLayer() {
        gradientLayer.frame = frame
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
