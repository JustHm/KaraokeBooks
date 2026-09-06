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
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textColor = .customPrimaryText
        return label
    }()

    private let textStack = UIStackView()
    private let memoRow = UIStackView()
    private var emptyMemoHeight: Constraint?
    private var memoTopConstraint: Constraint?
    private lazy var memoIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "note.text"))
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .caption1)
        imageView.adjustsImageSizeForAccessibilityContentSizeCategory = true
        imageView.tintColor = .customSecondaryText
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.isAccessibilityElement = false
        return imageView
    }()
    private lazy var memoLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .customSecondaryText
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        updateTextLayoutForPreferredContentSizeCategory()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory else { return }
        updateTextLayoutForPreferredContentSizeCategory()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateTextLayoutForPreferredContentSizeCategory()
    }

    func setup(rank _: Int, song: Song) {
        titleLabel.text = song.title
        singerLabel.text = song.singer
        numberLabel.text = song.no
        memoLabel.text = song.memo?.components(separatedBy: .newlines).joined(separator: " ")
        let hasMemo = song.memo?.isEmpty == false
        memoRow.isHidden = !hasMemo
        memoTopConstraint?.update(offset: hasMemo ? 4.0 : 0.0)
        if hasMemo { emptyMemoHeight?.deactivate() }
        else { emptyMemoHeight?.activate() }
        accessibilityLabel = String(
            format: String(localized: "accessibility.song"),
            locale: .current,
            song.no,
            song.title,
            song.singer
        )
        if let memo = song.memo, !memo.isEmpty {
            accessibilityLabel = (accessibilityLabel ?? "") + ", " + memo
        }
        updateAccessibilityHint()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        updateAccessibilityHint()
    }

    private func updateAccessibilityHint() {
        accessibilityHint = isEditing
            ? String(localized: "accessibility.songSelectHint")
            : String(localized: "accessibility.songHint")
    }

    private func setupViews() {
        let selectedBackground = UIView()
        selectedBackground.backgroundColor = .customForeground
        selectedBackgroundView = selectedBackground
        isAccessibilityElement = true
        accessibilityTraits = .button
        backgroundColor = .customForeground
        contentView.backgroundColor = .customForeground
        [numberLabel, textStack, memoRow].forEach {
            $0.isAccessibilityElement = false
            contentView.addSubview($0)
        }
        numberLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        numberLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        singerLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        textStack.axis = .vertical
        textStack.spacing = 4.0
        [titleLabel, singerLabel].forEach {
            $0.isAccessibilityElement = false
            textStack.addArrangedSubview($0)
        }
        textStack.snp.makeConstraints {
            $0.left.equalTo(numberLabel.snp.right).offset(8.0)
            $0.top.right.equalTo(contentView).inset(8.0)
        }
        numberLabel.snp.makeConstraints {
            $0.centerY.equalTo(textStack)
            $0.width.equalTo(70.0)
            $0.left.equalTo(contentView).inset(16.0)
        }
        memoRow.axis = .horizontal
        memoRow.alignment = .center
        memoRow.spacing = 5
        memoLabel.isAccessibilityElement = false
        memoLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        [memoIconView, memoLabel].forEach { memoRow.addArrangedSubview($0) }
        memoRow.snp.makeConstraints {
            $0.left.equalTo(contentView).inset(16.0)
            $0.right.equalTo(contentView).inset(8.0)
            memoTopConstraint = $0.top.equalTo(textStack.snp.bottom).constraint
            $0.bottom.equalTo(contentView).inset(8.0)
            emptyMemoHeight = $0.height.equalTo(0).constraint
        }
        memoRow.isHidden = true
    }

    private func updateTextLayoutForPreferredContentSizeCategory() {
        let usesExpandedLayout = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
            || titleLabel.font.pointSize >= 20.0
        titleLabel.numberOfLines = usesExpandedLayout ? 0 : 1
        singerLabel.numberOfLines = usesExpandedLayout ? 0 : 1
        titleLabel.lineBreakMode = usesExpandedLayout ? .byWordWrapping : .byTruncatingTail
        singerLabel.lineBreakMode = usesExpandedLayout ? .byWordWrapping : .byTruncatingTail
    }
}
