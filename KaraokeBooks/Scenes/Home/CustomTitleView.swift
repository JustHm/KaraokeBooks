//
//  CustomTitleView.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/03/22.
//

import UIKit
import SnapKit

final class CustomTitleView: UIView {
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "노래방Book"
        label.font = .systemFont(ofSize: 16.0, weight: .bold)
        label.textColor = .customPrimaryText
        return label
    }()
    lazy var brandSegmentControl: ClearSegmentedControl = {
        let segmentControl = ClearSegmentedControl()
        BrandType.allCases.enumerated().forEach { (index, value) in
            segmentControl.insertSegment(withTitle: value.replace,
                                         at: index,
                                         animated: true)
        }
        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self,
                                 action: #selector(didChangedBrandType),
                                 for: .valueChanged)
        return segmentControl
    }()
    var segmentControlEvent: ((BrandType) -> Void)
    init(frame: CGRect, segmentControlEvent: @escaping (BrandType) -> Void) {
        self.segmentControlEvent = segmentControlEvent
        super.init(frame: frame)
        setupLayout()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        [titleLabel, brandSegmentControl].forEach {
            addSubview($0)
        }
        titleLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        brandSegmentControl.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8.0)
            $0.left.right.equalToSuperview()
        }
    }
    
    @objc func didChangedBrandType(_ sender: UISegmentedControl) {
        let selectedBrand = BrandType.allCases[sender.selectedSegmentIndex]
        segmentControlEvent(selectedBrand)
    }
}
