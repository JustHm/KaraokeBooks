//
//  BottomBannerAdView.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 8/30/26.
//


import SnapKit
import GoogleMobileAds

final class BottomBannerAdView: UIView, BannerViewDelegate {
    var onHeightChanged: ((CGFloat) -> Void)?

    private weak var rootViewController: UIViewController?
    private var bannerView: BannerView?
    private var isLoadingAd = false
    private var hasRetriedAd = false
    private var requestedWidth = 0.0
    private var retryWorkItem: DispatchWorkItem?
    private var isBannerEnabled = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .customBackground
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setEnabled(_ isEnabled: Bool, rootViewController: UIViewController) {
        self.rootViewController = rootViewController

        guard isBannerEnabled != isEnabled else {
            if isEnabled { setNeedsLayout() }
            return
        }

        isBannerEnabled = isEnabled
        guard isEnabled else {
            retryWorkItem?.cancel()
            retryWorkItem = nil
            bannerView?.delegate = nil
            bannerView?.removeFromSuperview()
            bannerView = nil
            isLoadingAd = false
            hasRetriedAd = false
            requestedWidth = 0.0
            onHeightChanged?(0.0)
            return
        }

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        requestAdIfNeeded()
    }

    private func requestAdIfNeeded() {
        guard isBannerEnabled,
              let rootViewController,
              let adUnitID else { return }

        let availableWidth = rootViewController.view.bounds
            .inset(by: rootViewController.view.safeAreaInsets)
            .width
        guard availableWidth > 0.0 else { return }

        if let bannerView,
           abs(requestedWidth - availableWidth) > 0.5 {
            retryWorkItem?.cancel()
            retryWorkItem = nil
            bannerView.removeFromSuperview()
            self.bannerView = nil
            isLoadingAd = false
            hasRetriedAd = false
            onHeightChanged?(0.0)
        }

        guard !isLoadingAd,
              bannerView == nil,
              retryWorkItem == nil else { return }

        isLoadingAd = true
        requestedWidth = availableWidth
        let bannerView = BannerView(
            adSize: currentOrientationAnchoredAdaptiveBanner(width: availableWidth)
        )
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = rootViewController
        bannerView.delegate = self
        bannerView.alpha = 0.0
        self.bannerView = bannerView
        bannerView.load(Request())
    }

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        guard isBannerEnabled,
              bannerView === self.bannerView,
              bannerView.superview == nil else { return }

        isLoadingAd = false
        addSubview(bannerView)
        bannerView.snp.makeConstraints {
            $0.centerX.bottom.equalToSuperview()
        }
        onHeightChanged?(bannerView.adSize.size.height)
        UIView.animate(withDuration: 0.2) {
            bannerView.alpha = 1.0
        }
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        guard bannerView === self.bannerView else { return }

        self.bannerView = nil
        isLoadingAd = false
        guard !hasRetriedAd else {
            onHeightChanged?(0.0)
            return
        }

        hasRetriedAd = true
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.retryWorkItem = nil
            self.requestAdIfNeeded()
        }
        retryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0, execute: workItem)
    }

    private var adUnitID: String? {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2435281174"
        #else
        guard let adUnitID = Bundle.main.object(
            forInfoDictionaryKey: "GADBannerAdUnitID"
        ) as? String,
        !adUnitID.isEmpty else { return nil }
        return adUnitID
        #endif
    }
}
