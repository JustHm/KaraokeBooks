//
//  SongInfoStackView.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/10.
//

import UIKit

final class SongInfoStackView: UIStackView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .title3).scaledFont(
            for: .systemFont(ofSize: 20.0, weight: .bold)
        )
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .customPrimaryText
        label.numberOfLines = 0
        return label
    }()
    private lazy var singerLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .customSecondaryText
        label.numberOfLines = 0
        return label
    }()
    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .systemRed
        return label
    }()
    private lazy var composerLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .customSecondaryText
        label.numberOfLines = 0
        return label
    }()
    private lazy var lyricistLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .customSecondaryText
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
        }
    }
    func setupLabelText(song: Song) {
        titleLabel.text = song.title
        singerLabel.text = song.singer
        numberLabel.text = "\(song.brand.name) · \(song.no)"
        composerLabel.text = "작곡  \(song.composer)"
        lyricistLabel.text = "작사  \(song.lyricist)"
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
