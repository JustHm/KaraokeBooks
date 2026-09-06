//
//  SongDetailViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/10.
//

import SwiftUI
import ReactorKit
import SafariServices

/// UIKit owns presentation; layout and memo editing live in SongDetailView.
final class SongDetailViewController: UIHostingController<SongDetailView> {
    private let reactor: SongDetailReactor
    private let model: SongDetailViewModel
    private let disposeBag = DisposeBag()
    private var returnDetent: UISheetPresentationController.Detent.Identifier?
    private var isEditingMemo = false

    init(reactor: SongDetailReactor) {
        self.reactor = reactor
        let model = SongDetailViewModel(state: reactor.currentState)
        self.model = model
        super.init(rootView: SongDetailView(model: model))
        rootView.onAction = { [weak reactor] in reactor?.action.onNext($0) }
        rootView.onEditingChanged = { [weak self] in self?.setMemoEditing($0) }
        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSheet()
        reactor.state.observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.model.state = $0 })
            .disposed(by: disposeBag)
        reactor.pulse(\.$youtubeURL).compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] url in
                guard let self else { return }
                MRSearchInterstitialAdController.shared.presentIfEligible(from: self) {
                    self.present(SFSafariViewController(url: url), animated: true)
                }
            }).disposed(by: disposeBag)
        reactor.pulse(\.$errorMessage).compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                let alert = UIAlertController(title: String(localized: "alert.errorTitle"), message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: String(localized: "action.ok"), style: .default))
                self?.present(alert, animated: true)
            }).disposed(by: disposeBag)
        reactor.action.onNext(.viewDidLoad)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            configureSheet()
        }
    }

    private func configureSheet() {
        guard let sheet = sheetPresentationController else { return }
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            sheet.detents = [.large()]
            sheet.selectedDetentIdentifier = .large
        } else if #available(iOS 16.0, *) {
            let compact = UISheetPresentationController.Detent.Identifier("songDetail")
            sheet.detents = [.custom(identifier: compact) { min(460, $0.maximumDetentValue) }, .large()]
            sheet.selectedDetentIdentifier = isEditingMemo ? .large : compact
        } else {
            sheet.detents = [.medium(), .large()]
            sheet.selectedDetentIdentifier = isEditingMemo ? .large : .medium
        }
        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = 28
        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
    }

    private func setMemoEditing(_ editing: Bool) {
        guard editing != isEditingMemo else { return }
        isEditingMemo = editing
        isModalInPresentation = editing
        if editing { returnDetent = sheetPresentationController?.selectedDetentIdentifier }
        sheetPresentationController?.animateChanges {
            self.sheetPresentationController?.selectedDetentIdentifier = editing ? .large : self.returnDetent
        }
    }
}
