//
//  NativeAdPlacementController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/08/31.
//

import UIKit
import GoogleMobileAds

final class NativeAdPlacementController: NSObject {
    private static let maximumAdsPerRequest = 5

    private weak var rootViewController: UIViewController?

    private var nativeAdLoader: AdLoader?
    private var nativeAds: [NativeAd] = []
    private var desiredAdCount = 0
    private var maximumAdCount = 0
    private var retryWorkItem: DispatchWorkItem?
    private var hasRetried = false
    private var isEnabled = false
    private var adsRequestedInCurrentLoad = 0
    private var adCountBeforeCurrentLoad = 0
    private let registeredCells = NSMapTable<NSNumber, NativeAdTableViewCell>.strongToWeakObjects()

    var onAvailabilityChanged: (() -> Void)?
    var availableAdCount: Int {
        isEnabled ? min(nativeAds.count, desiredAdCount) : 0
    }

    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }

    func setEnabled(_ isEnabled: Bool, maximumAdCount: Int) {
        self.isEnabled = isEnabled
        self.maximumAdCount = maximumAdCount

        guard isEnabled else {
            registeredCells.objectEnumerator()?.allObjects.forEach { ($0 as? NativeAdTableViewCell)?.clearAd() }
            registeredCells.removeAllObjects()
            retryWorkItem?.cancel()
            retryWorkItem = nil
            hasRetried = false
            adsRequestedInCurrentLoad = 0
            adCountBeforeCurrentLoad = 0
            desiredAdCount = 0
            onAvailabilityChanged?()
            return
        }

        desiredAdCount = min(1, maximumAdCount)
        loadIfNeeded()
        onAvailabilityChanged?()
    }

    func requestAds(upTo requestedAdCount: Int) {
        guard isEnabled else { return }
        let targetCount = min(requestedAdCount, maximumAdCount)
        guard targetCount > desiredAdCount else { return }
        desiredAdCount = targetCount
        loadIfNeeded()
    }

    func loadIfNeeded() {
        guard !AppEnvironment.isUITesting,
              isEnabled,
              nativeAdLoader == nil,
              nativeAds.count < desiredAdCount,
              let rootViewController,
              let adUnitID = nativeAdUnitID else { return }

        let requestedAdCount = min(
            desiredAdCount - nativeAds.count,
            Self.maximumAdsPerRequest
        )
        guard requestedAdCount > 0 else { return }

        let loaderOptions: [MultipleAdsAdLoaderOptions]? = {
            guard requestedAdCount > 1 else { return nil }
            let options = MultipleAdsAdLoaderOptions()
            options.numberOfAds = requestedAdCount
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
        adsRequestedInCurrentLoad = requestedAdCount
        adCountBeforeCurrentLoad = nativeAds.count
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
        // A reused cell must no longer be registered under its previous slot.
        for oldKey in registeredCells.keyEnumerator().allObjects.compactMap({ $0 as? NSNumber })
            where registeredCells.object(forKey: oldKey) === cell {
            registeredCells.removeObject(forKey: oldKey)
        }
        let key = NSNumber(value: slot)
        if let previous = registeredCells.object(forKey: key), previous !== cell {
            previous.clearAd()
        }
        registeredCells.setObject(cell, forKey: key)
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
        let receivedAdCount = nativeAds.count - adCountBeforeCurrentLoad
        guard receivedAdCount == adsRequestedInCurrentLoad else { return }
        loadIfNeeded()
    }
}

extension NativeAdPlacementController: NativeAdDelegate {}
