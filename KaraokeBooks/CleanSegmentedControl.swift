//
//  CleanSegmentedControl.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import UIKit

final class ClearSegmentedControl: UISegmentedControl {
    init() {
        super.init(frame: .zero)
        let emptyImage = imageWithColor(color: .clear) // image에 size가 없으면 아예 안보이더라 그래서 꼭 이렇게 만들어줘야함.
        let divider = UIImage()
        let defaultFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
        //배경색 제거
        self.setBackgroundImage(emptyImage, for: .normal, barMetrics: .default)
        self.setBackgroundImage(emptyImage, for: .selected, barMetrics: .default)
        self.setBackgroundImage(emptyImage, for: .highlighted, barMetrics: .default)
        self.setDividerImage(divider, forLeftSegmentState: .selected, rightSegmentState: .normal, barMetrics: .default)
        //선택, 선택 안됐을 때 텍스트 설정과 구분선 제거
        
        self.setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.gray,
            NSAttributedString.Key.font: defaultFont
        ], for: .normal)
        self.setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.red,
            NSAttributedString.Key.font: defaultFont
        ], for: .selected)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 32.0, height: 32.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor);
        context!.fill(rect);
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image!
    }
    
    private lazy var underlineView: UIView = {
        let width = self.bounds.size.width / CGFloat(self.numberOfSegments)
        let height = 2.0
        let xPosition = CGFloat(self.selectedSegmentIndex * Int(width))
        let yPosition = self.bounds.size.height - 1.0
        let frame = CGRect(x: xPosition, y: yPosition, width: width, height: height)
        let view = UIView(frame: frame)
        view.backgroundColor = .red
        self.addSubview(view)
        return view
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let underlineFinalXPosition = (self.bounds.width / CGFloat(self.numberOfSegments)) * CGFloat(self.selectedSegmentIndex)
        UIView.animate(
            withDuration: 0.1,
            animations: {
                self.underlineView.frame.origin.x = underlineFinalXPosition
            }
        )
        layer.cornerRadius = 0
    }
}

