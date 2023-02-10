//
//  SongDetailStackView.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/10.
//

import UIKit

final class SongDetailStackView: UIStackView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        return label
    }()
    private lazy var singerLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        return label
    }()
    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        return label
    }()
    private lazy var composerLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        return label
    }()
    private lazy var lyricistLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        [
            titleLabel,
            singerLabel,
            numberLabel,
            composerLabel,
            lyricistLabel
        ].forEach {
            addArrangedSubview($0)
            $0.text = "1111 1111"
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

