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
    private weak var tableView: UITableView?
    private let cardView = NativeAdCardView()

    private var nativeAdLoader: AdLoader?
    private var nativeAd: NativeAd?
    private var retryWorkItem: DispatchWorkItem?
    private var hasRetried = false
    private var isEnabled = false

    init(rootViewController: UIViewController, tableView: UITableView) {
        self.rootViewController = rootViewController
        self.tableView = tableView
    }

    func setEnabled(_ isEnabled: Bool) {
        self.isEnabled = isEnabled

        guard isEnabled else {
            retryWorkItem?.cancel()
            retryWorkItem = nil
            hasRetried = false
            tableView?.tableHeaderView = nil
            return
        }

        if let nativeAd {
            display(nativeAd)
        } else {
            loadIfNeeded()
        }
    }

    func loadIfNeeded() {
        guard isEnabled,
              nativeAdLoader == nil,
              nativeAd == nil,
              let rootViewController,
              let adUnitID = nativeAdUnitID else { return }

        let loader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: nil
        )
        loader.delegate = self
        nativeAdLoader = loader
        loader.load(Request())
    }

    private func scheduleRetry() {
        guard isEnabled,
              !hasRetried,
              nativeAd == nil else { return }

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

    private func display(_ nativeAd: NativeAd) {
        guard isEnabled,
              let rootViewController,
              let tableView else { return }

        cardView.populate(with: nativeAd)
        rootViewController.view.layoutIfNeeded()
        cardView.sizeToFit(width: tableView.bounds.width)
        tableView.tableHeaderView = cardView
        cardView.associate(with: nativeAd)
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
        self.nativeAd = nativeAd
        display(nativeAd)
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
