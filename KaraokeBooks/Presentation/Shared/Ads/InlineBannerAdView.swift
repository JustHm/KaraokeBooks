//
//  InlineBannerAdView.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/09/11.
//

import UIKit
import SnapKit
import GoogleMobileAds

final class InlineBannerAdView: UIView, BannerViewDelegate {
    var onHeightChanged: ((CGFloat) -> Void)?

    private var bannerView: BannerView?
    private var isLoadingAd = false
    private var requestedWidth = 0.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        requestAdIfNeeded()
    }

    private func requestAdIfNeeded() {
        guard let rootViewController = containingViewController,
              let adUnitID,
              bounds.width > 0.0 else { return }

        if let bannerView, abs(requestedWidth - bounds.width) > 0.5 {
            bannerView.removeFromSuperview()
            self.bannerView = nil
            isLoadingAd = false
            onHeightChanged?(0.0)
        }

        guard !isLoadingAd, bannerView == nil else { return }

        isLoadingAd = true
        requestedWidth = bounds.width
        let bannerView = BannerView(adSize: currentOrientationInlineAdaptiveBanner(width: bounds.width))
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = rootViewController
        bannerView.delegate = self
        bannerView.alpha = 0.0
        self.bannerView = bannerView
        bannerView.load(Request())
    }

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        guard bannerView === self.bannerView, bannerView.superview == nil else { return }

        isLoadingAd = false
        addSubview(bannerView)
        bannerView.snp.makeConstraints { $0.edges.equalToSuperview() }
        onHeightChanged?(bannerView.adSize.size.height)
        UIView.animate(withDuration: 0.2) {
            bannerView.alpha = 1.0
        }
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        guard bannerView === self.bannerView else { return }
        self.bannerView = nil
        isLoadingAd = false
        onHeightChanged?(0.0)
    }

    private var containingViewController: UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let viewController = current as? UIViewController { return viewController }
            responder = current.next
        }
        return window?.rootViewController
    }

    private var adUnitID: String? {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2934735716"
        #else
        guard let adUnitID = Bundle.main.object(
            forInfoDictionaryKey: "GADBannerAdUnitID"
        ) as? String,
        !adUnitID.isEmpty else { return nil }
        return adUnitID
        #endif
    }
}
