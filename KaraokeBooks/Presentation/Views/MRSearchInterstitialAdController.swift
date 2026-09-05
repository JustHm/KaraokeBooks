//
//  MRSearchInterstitialAdController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/09/04.
//

import Foundation
import GoogleMobileAds
import UIKit

final class MRSearchInterstitialAdController: NSObject {
    static let shared = MRSearchInterstitialAdController()

    private enum UserDefaultsKey {
        static let lastPresentationDate = "MRSearchInterstitialAdLastPresentationDate"
    }

    private let minimumSearchCount = 2
    private var minimumPresentationInterval: TimeInterval {
        #if DEBUG
        return 0.0
        #else
        return 15.0 * 60.0
        #endif
    }
    private var searchCount = 0
    private var interstitialAd: InterstitialAd?
    private var isLoadingAd = false
    private var isPresentingAd = false
    private var pendingYouTubePresentation: (() -> Void)?

    private override init() {}

    func preload() {
        guard !isLoadingAd, interstitialAd == nil, let adUnitID else { return }

        isLoadingAd = true
        InterstitialAd.load(with: adUnitID, request: Request()) { [weak self] ad, _ in
            guard let self else { return }
            self.isLoadingAd = false
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
        }
    }

    func presentIfEligible(
        from viewController: UIViewController,
        completion: @escaping () -> Void
    ) {
        searchCount += 1

        guard searchCount >= minimumSearchCount,
              canPresentAd,
              let interstitialAd,
              !isPresentingAd else {
            completion()
            preload()
            return
        }

        self.interstitialAd = nil
        isPresentingAd = true
        pendingYouTubePresentation = completion
        interstitialAd.present(from: viewController)
    }

    private var canPresentAd: Bool {
        guard let lastPresentationDate = UserDefaults.standard.object(
            forKey: UserDefaultsKey.lastPresentationDate
        ) as? Date else {
            return true
        }
        return Date().timeIntervalSince(lastPresentationDate) >= minimumPresentationInterval
    }

    private var adUnitID: String? {
        #if DEBUG
        return "ca-app-pub-3940256099942544/4411468910"
        #else
        guard let adUnitID = Bundle.main.object(
            forInfoDictionaryKey: "GADMRSearchInterstitialAdUnitID"
        ) as? String,
        !adUnitID.isEmpty else { return nil }
        return adUnitID
        #endif
    }

    private func completeAdPresentation() {
        isPresentingAd = false

        let completion = pendingYouTubePresentation
        pendingYouTubePresentation = nil
        completion?()
        preload()
    }
}

extension MRSearchInterstitialAdController: FullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        UserDefaults.standard.set(Date(), forKey: UserDefaultsKey.lastPresentationDate)
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        completeAdPresentation()
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        completeAdPresentation()
    }
}
