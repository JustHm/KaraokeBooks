//
//  RankTableViewHeader.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import UIKit
import SnapKit

final class RankTableViewHeader: UITableViewHeaderFooterView {
    static let identifier = "RankTableViewHeader"
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18.0, weight: .bold)
        label.text = "인기 차트"
        return label
    }()
    private lazy var dateSegmentedControl: ClearSegmentedControl = {
        let segmentedControl = ClearSegmentedControl()
        RankDateType.allCases.enumerated()
            .forEach { (index, section) in
                segmentedControl.insertSegment(
                    withTitle: section.replace,
                    at: index,
                    animated: false)
            }
        segmentedControl.selectedSegmentIndex = 0;
//        segmentedControl.addTarget(
//            self,
//            action: #selector(valueChangedDateSegmentedControl),
//            for: .valueChanged)
        return segmentedControl
    }()
    
    func setup() {
        setupViews()
    }
    
    private func setupViews() {
        [titleLabel, dateSegmentedControl].forEach {
            addSubview($0)
        }
        titleLabel.snp.makeConstraints {
            $0.left.equalToSuperview().inset(16.0)
            $0.top.bottom.equalToSuperview()
        }
        dateSegmentedControl.snp.makeConstraints {
            $0.right.equalToSuperview().inset(8.0)
            $0.top.bottom.equalTo(titleLabel)
        }
    }
}
