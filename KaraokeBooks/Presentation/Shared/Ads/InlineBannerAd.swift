//
//  InlineBannerAd.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/09/06.
//

import SwiftUI

struct InlineBannerAd: UIViewRepresentable {
    @Binding var height: CGFloat

    func makeUIView(context: Context) -> InlineBannerAdView {
        let view = InlineBannerAdView()
        let height = $height
        view.onHeightChanged = { newHeight in
            DispatchQueue.main.async {
                height.wrappedValue = newHeight
            }
        }
        return view
    }

    func updateUIView(_ uiView: InlineBannerAdView, context: Context) {}
}
