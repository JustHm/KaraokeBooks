//
//  MoveSceneButton.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 11/21/24.
//

import UIKit

final class MoveSceneButton: UIButton {
    private lazy var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        let colors: [CGColor] = [
            .init(red: 0.84, green: 0.05, blue: 0.33, alpha: 1.00), //#D60C55
            .init(red: 0.71, green: 0.17, blue: 0.48, alpha: 1.00), //#B42B7B
            .init(red: 0.52, green: 0.26, blue: 0.55, alpha: 1.00)  //#84438D
        ]
        gradientLayer.colors = colors
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        layer.insertSublayer(gradientLayer, at: 0)
        return gradientLayer
    }()
    var title: String?
    var symbol: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(title: String, symbol: String) { // star, magnifyingglass
        super.init(frame: .zero)
        self.title = title
        self.symbol = symbol
        setProperties()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds //frame을 했을때는 왜 안되나?
        //gradientLayer.frame에 frame 대신 bounds를 사용하는 것이 적절합니다. 이는 레이아웃이 변경될 때 gradient가 버튼의 크기와 위치에 맞게 조정되도록 보장합니다.
    }
    
    func setProperties() {
        self.tintColor = .black
        setTitle(title, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16.0, weight: .bold)
        if let symbol {
            setImage(UIImage(systemName: symbol)?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        }
        backgroundColor = .init(red: 0.84, green: 0.05, blue: 0.33, alpha: 1.00) //#D60C55
        layer.cornerRadius = 15.0
        self.clipsToBounds = true
    }
}
