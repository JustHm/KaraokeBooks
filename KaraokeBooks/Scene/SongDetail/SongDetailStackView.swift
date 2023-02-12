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
        label.textColor = .customPrimaryText
        label.numberOfLines = 0
        return label
    }()
    private lazy var singerLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.textColor = .customPrimaryText
        label.numberOfLines = 0
        return label
    }()
    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.textColor = .customPrimaryText
        return label
    }()
    private lazy var composerLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.textColor = .customPrimaryText
        label.numberOfLines = 0
        return label
    }()
    private lazy var lyricistLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.textColor = .customPrimaryText
        label.numberOfLines = 0
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
    func setupLabelText(song: Song) {
        titleLabel.text = "제목: \(song.title)"
        singerLabel.text = "가수: \(song.singer)"
        numberLabel.text = "번호: \(song.no)"
        composerLabel.text = "작곡: \(song.composer)"
        lyricistLabel.text = "작사: \(song.lyricist)"
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

