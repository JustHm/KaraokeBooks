//
//  NativeAdPlacementController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/08/31.
//

import UIKit
import GoogleMobileAds

final class NativeAdPlacementController: NSObject {
    private weak var rootViewController: UIViewController?

    private var nativeAdLoader: AdLoader?
    private var nativeAds: [NativeAd] = []
    private var desiredAdCount = 0
    private var retryWorkItem: DispatchWorkItem?
    private var hasRetried = false
    private var isEnabled = false

    var onAvailabilityChanged: (() -> Void)?
    var availableAdCount: Int {
        isEnabled ? nativeAds.count : 0
    }

    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }

    func setEnabled(_ isEnabled: Bool, desiredAdCount: Int) {
        self.isEnabled = isEnabled
        self.desiredAdCount = desiredAdCount

        guard isEnabled else {
            retryWorkItem?.cancel()
            retryWorkItem = nil
            hasRetried = false
            onAvailabilityChanged?()
            return
        }

        loadIfNeeded()
        onAvailabilityChanged?()
    }

    func loadIfNeeded() {
        guard !AppEnvironment.isUITesting,
              isEnabled,
              nativeAdLoader == nil,
              nativeAds.count < desiredAdCount,
              let rootViewController,
              let adUnitID = nativeAdUnitID else { return }

        let loaderOptions: [MultipleAdsAdLoaderOptions]? = {
            guard desiredAdCount > 1 else { return nil }
            let options = MultipleAdsAdLoaderOptions()
            options.numberOfAds = desiredAdCount
            return [options]
        }()
        let loader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: loaderOptions
        )
        loader.delegate = self
        nativeAdLoader = loader
        loader.load(Request())
    }

    private func scheduleRetry() {
        guard isEnabled,
              !hasRetried,
              nativeAds.isEmpty else { return }

        hasRetried = true
        let workItem = DispatchWorkItem { [weak self] in
            guard let self,
                  self.isEnabled,
                  self.rootViewController?.viewIfLoaded?.window != nil else { return }
            self.retryWorkItem = nil
            self.loadIfNeeded()
        }
        retryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0, execute: workItem)
    }

    func configure(_ cell: NativeAdTableViewCell, slot: Int) {
        guard isEnabled,
              nativeAds.indices.contains(slot) else { return }
        cell.configure(with: nativeAds[slot])
    }

    private var nativeAdUnitID: String? {
        #if DEBUG
        return "ca-app-pub-3940256099942544/3986624511"
        #else
        guard let adUnitID = Bundle.main.object(
            forInfoDictionaryKey: "GADNativeAdUnitID"
        ) as? String,
        !adUnitID.isEmpty else { return nil }
        return adUnitID
        #endif
    }
}

extension NativeAdPlacementController: NativeAdLoaderDelegate, AdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        nativeAd.delegate = self
        nativeAds.append(nativeAd)
        onAvailabilityChanged?()
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        nativeAdLoader = nil
        scheduleRetry()
    }

    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        nativeAdLoader = nil
    }
}

extension NativeAdPlacementController: NativeAdDelegate {}
