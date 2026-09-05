//
//  NativeAdTableViewCell.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/08/31.
//

import UIKit
import SnapKit
import GoogleMobileAds

final class NativeAdTableViewCell: UITableViewCell {
    static let identifier = "NativeAdTableViewCell"

    private let nativeAdCardView = NativeAdCardView()
    private var pendingNativeAd: NativeAd?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        clearAd()
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        // Native ads are interactive content, not selectable songs.
        super.setEditing(false, animated: animated)
    }

    func clearAd() {
        pendingNativeAd = nil
        nativeAdCardView.reset()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let pendingNativeAd,
              nativeAdCardView.bounds.width > 0.0 else { return }

        nativeAdCardView.associate(with: pendingNativeAd)
        self.pendingNativeAd = nil
    }

    func configure(with nativeAd: NativeAd) {
        pendingNativeAd = nativeAd
        nativeAdCardView.populate(with: nativeAd)
        setNeedsLayout()
    }

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(nativeAdCardView)
        nativeAdCardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
