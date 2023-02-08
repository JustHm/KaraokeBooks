//
//  RankTableViewCell.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import UIKit
import SnapKit

final class RankTableViewCell: UITableViewCell {
    static let identifier = "RankTableViewCell"
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .bold)
        return label
    }()
    private lazy var singerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        return label
    }()
    func setup(song: Song) {
        titleLabel.text = song.title
        singerLabel.text = song.singer
        numberLabel.text = "No.\(song.no)"
//        backgroundColor = .secondaryLabel
        setupViews()
    }
    
    private func setupViews() {
        [numberLabel, titleLabel, singerLabel].forEach {
            addSubview($0)
        }
        numberLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().inset(16.0)
        }
        titleLabel.snp.makeConstraints {
            $0.left.equalTo(numberLabel.snp.right).offset(8.0)
            $0.top.equalToSuperview().inset(8.0)
        }
        singerLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4.0)
            $0.bottom.equalToSuperview().inset(8.0)
            $0.left.equalTo(titleLabel)
        }
        
    }
}
