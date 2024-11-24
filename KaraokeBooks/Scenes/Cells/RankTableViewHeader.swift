//
//  RankTableViewHeader.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import UIKit
import SnapKit

final class RankTableViewHeader: UIView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22.0, weight: .bold)
        label.text = "인기 차트"
        return label
    }()
    lazy var dateMenu: UIButton = {
        let button = UIButton()
        let actions = RankDateType.allCases.map {
            UIAction(title: $0.rawValue, handler: { [weak self] action in
                button.setTitle(action.title, for: .normal)
            })
        }
        let menu = UIMenu(children: actions)
        button.menu = menu
        button.showsMenuAsPrimaryAction = true
        button.setTitle("일간", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 22.0, weight: .bold)
        
        return button
    }()
    lazy var dateSegmentedControl: ClearSegmentedControl = {
        let segmentedControl = ClearSegmentedControl()
        RankDateType.allCases.enumerated()
            .forEach { (index, section) in
                segmentedControl.insertSegment(
                    withTitle: section.rawValue,
                    at: index,
                    animated: false)
            }
        segmentedControl.selectedSegmentIndex = 0;
        return segmentedControl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        [dateMenu, titleLabel].forEach {
            addSubview($0)
        }
        dateMenu.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }
        titleLabel.snp.makeConstraints {
            $0.left.equalTo(dateMenu.snp.right).offset(8.0)
            $0.top.bottom.equalToSuperview()
        }
    }
}
