//
//  NativeAdCardView.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/08/31.
//

import UIKit
import SnapKit
import GoogleMobileAds

final class NativeAdCardView: NativeAdView {
    private lazy var adLabel: UILabel = {
        let label = UILabel()
        label.text = "광고"
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8.0
        imageView.clipsToBounds = true
        imageView.backgroundColor = .tertiarySystemFill
        return imageView
    }()

    private lazy var headlineLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .customPrimaryText
        label.numberOfLines = 1
        return label
    }()

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()

    private lazy var callToActionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemPink
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.layer.cornerRadius = 10.0
        button.isUserInteractionEnabled = false
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .customForeground
        [adLabel, iconImageView, headlineLabel, bodyLabel, callToActionButton].forEach {
            addSubview($0)
        }
        adLabel.snp.makeConstraints {
            $0.top.left.equalToSuperview().inset(16.0)
            $0.right.lessThanOrEqualToSuperview().inset(64.0)
        }
        iconImageView.snp.makeConstraints {
            $0.top.equalTo(adLabel.snp.bottom).offset(8.0)
            $0.left.equalToSuperview().inset(16.0)
            $0.size.equalTo(44.0)
        }
        headlineLabel.snp.makeConstraints {
            $0.top.equalTo(iconImageView)
            $0.left.equalTo(iconImageView.snp.right).offset(12.0)
            $0.right.equalToSuperview().inset(16.0)
        }
        bodyLabel.snp.makeConstraints {
            $0.top.equalTo(headlineLabel.snp.bottom).offset(4.0)
            $0.left.right.equalTo(headlineLabel)
        }
        callToActionButton.snp.makeConstraints {
            $0.top.greaterThanOrEqualTo(iconImageView.snp.bottom).offset(14.0)
            $0.top.greaterThanOrEqualTo(bodyLabel.snp.bottom).offset(14.0)
            $0.left.right.equalToSuperview().inset(16.0)
            $0.height.greaterThanOrEqualTo(40.0)
            $0.bottom.equalToSuperview().inset(16.0)
        }

        headlineView = headlineLabel
        bodyView = bodyLabel
        callToActionView = callToActionButton
        iconView = iconImageView
    }

    func populate(with nativeAd: NativeAd) {
        self.nativeAd = nil
        headlineLabel.text = nativeAd.headline
        bodyLabel.text = nativeAd.body
        bodyLabel.isHidden = nativeAd.body == nil
        iconImageView.image = nativeAd.icon?.image
        iconImageView.isHidden = nativeAd.icon == nil
        callToActionButton.setTitle(nativeAd.callToAction, for: .normal)
        callToActionButton.isHidden = nativeAd.callToAction == nil
    }

    func associate(with nativeAd: NativeAd) {
        self.nativeAd = nativeAd
    }

    func reset() {
        nativeAd = nil
        headlineLabel.text = nil
        bodyLabel.text = nil
        iconImageView.image = nil
        callToActionButton.setTitle(nil, for: .normal)
    }

    func sizeToFit(width: CGFloat) {
        frame = CGRect(x: 0.0, y: 0.0, width: width, height: 0.0)
        setNeedsLayout()
        layoutIfNeeded()
        let size = systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        frame.size.height = ceil(size.height)
        layoutIfNeeded()
    }
}
