//
//  SongTableViewCell.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import UIKit
import SnapKit

final class SongTableViewCell: UITableViewCell {
    static let identifier = "SongTableViewCell"
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textColor = .customPrimaryText
        return label
    }()
    private lazy var singerLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textColor = .customSecondaryText
        return label
    }()
    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textColor = .customPrimaryText
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(rank _: Int, song: Song) {
        titleLabel.text = song.title
        singerLabel.text = song.singer
        numberLabel.text = song.no
        accessibilityLabel = String(
            format: String(localized: "accessibility.song"),
            locale: .current,
            song.no,
            song.title,
            song.singer
        )
    }
    
    private func setupViews() {
        backgroundColor = .customForeground
        contentView.backgroundColor = .customForeground
        [numberLabel, titleLabel, singerLabel].forEach {
            contentView.addSubview($0)
        }
        numberLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        numberLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        singerLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        numberLabel.snp.makeConstraints {
            $0.centerY.equalTo(contentView)
            $0.width.equalTo(70.0)
            $0.left.equalTo(contentView).inset(16.0)
        }
        titleLabel.snp.makeConstraints {
            $0.left.equalTo(numberLabel.snp.right).offset(8.0)
            $0.top.right.equalTo(contentView).inset(8.0)
        }
        singerLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4.0)
            $0.bottom.equalTo(contentView).inset(8.0)
            $0.left.right.equalTo(titleLabel)
        }
    }
}
