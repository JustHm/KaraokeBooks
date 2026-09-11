//
//  FavoriteRouletteViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/09/06.
//

import UIKit
import SnapKit
import ReactorKit
import RxCocoa

final class FavoriteRouletteViewController: UIViewController, View {
    typealias Reactor = FavoriteRouletteReactor

    var disposeBag = DisposeBag()
    private let numberLabel = UILabel()
    private let titleLabel = UILabel()
    private let singerLabel = UILabel()
    private let memoLabel = UILabel()
    private let memoRow = UIStackView()
    private let statusLabel = UILabel()
    private let drawButton = UIButton(type: .system)
    private let detailButton = UIButton(type: .system)
    private let buttonStack = UIStackView()
    private let inlineBannerView = InlineBannerAdView()
    private var inlineBannerHeightConstraint: Constraint?

    init(reactor: FavoriteRouletteReactor) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
        modalPresentationStyle = .pageSheet
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customForeground
        sheetPresentationController?.detents = [.medium(), .large()]
        sheetPresentationController?.prefersGrabberVisible = true
        let scroll = UIScrollView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 18
        view.addSubview(scroll)
        scroll.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(36)
            $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
        }
        scroll.addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalTo(scroll.contentLayoutGuide)
            $0.width.equalTo(scroll.frameLayoutGuide)
        }
        numberLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 46, weight: .bold))
        numberLabel.textColor = .systemRed
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        singerLabel.font = .preferredFont(forTextStyle: .body)
        memoLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.font = .preferredFont(forTextStyle: .caption1)
        [numberLabel, titleLabel, singerLabel, memoLabel, statusLabel].forEach {
            $0.numberOfLines = 0
            $0.textAlignment = .center
            $0.adjustsFontForContentSizeCategory = true
        }
        [singerLabel, memoLabel, statusLabel].forEach { $0.textColor = .customSecondaryText }
        let memoIcon = UIImageView(image: UIImage(systemName: "note.text"))
        memoIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .subheadline)
            .applying(UIImage.SymbolConfiguration(weight: .semibold))
        memoIcon.adjustsImageSizeForAccessibilityContentSizeCategory = true
        memoIcon.tintColor = .customSecondaryText
        memoIcon.contentMode = .scaleAspectFit
        memoIcon.isAccessibilityElement = false
        memoIcon.setContentHuggingPriority(.required, for: .horizontal)
        memoIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        let leadingSpace = UIView()
        let trailingSpace = UIView()
        memoRow.axis = .horizontal
        memoRow.alignment = .center
        [leadingSpace, memoIcon, memoLabel, trailingSpace].forEach { memoRow.addArrangedSubview($0) }
        memoRow.setCustomSpacing(6, after: memoIcon)
        leadingSpace.snp.makeConstraints { $0.width.equalTo(trailingSpace) }
        memoLabel.textAlignment = .left
        memoLabel.lineBreakMode = .byTruncatingTail
        memoRow.isHidden = true
        drawButton.setTitle(String(localized: "roulette.draw"), for: .normal)
        drawButton.accessibilityIdentifier = "roulette.draw"
        detailButton.setTitle(String(localized: "roulette.detail"), for: .normal)
        [drawButton, detailButton].forEach { button in
            button.titleLabel?.font = .preferredFont(forTextStyle: .body)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.textAlignment = .center
            button.backgroundColor = .systemRed
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 12
            button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
        }
        [drawButton, detailButton].forEach { buttonStack.addArrangedSubview($0) }
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 12
        inlineBannerView.snp.makeConstraints {
            inlineBannerHeightConstraint = $0.height.equalTo(0.0).constraint
        }
        inlineBannerView.onHeightChanged = { [weak self] height in
            self?.inlineBannerHeightConstraint?.update(offset: height)
            self?.view.layoutIfNeeded()
        }
        [numberLabel, titleLabel, singerLabel, memoRow, buttonStack, inlineBannerView, statusLabel].forEach {
            stack.addArrangedSubview($0)
        }
        stack.setCustomSpacing(32, after: buttonStack)
        updateButtonLayout()
        reactor?.action.onNext(.draw)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            updateButtonLayout()
        }
    }

    private func updateButtonLayout() {
        buttonStack.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
    }

    func bind(reactor: FavoriteRouletteReactor) {
        reactor.state.distinctUntilChanged { $0.drawRevision == $1.drawRevision }
            .filter { $0.drawRevision > 1 }
            .compactMap { $0.song }
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { song in
                let announcement = String(format: String(localized: "accessibility.rouletteResult"),
                                          locale: .current, song.brand.name, song.no, song.title, song.singer)
                UIAccessibility.post(notification: .announcement, argument: announcement)
            }).disposed(by: disposeBag)
        drawButton.rx.tap.map { FavoriteRouletteReactor.Action.draw }.bind(to: reactor.action).disposed(by: disposeBag)
        detailButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let self, let song = reactor.currentState.song else { return }
            self.present(SongDetailViewController(reactor: SongDetailReactor(song: song)), animated: true)
        }).disposed(by: disposeBag)
        reactor.state.observe(on: MainScheduler.instance).subscribe(onNext: { [weak self] state in
            guard let self else { return }
            self.drawButton.isEnabled = !state.songs.isEmpty
            self.detailButton.isEnabled = state.song != nil
            guard let song = state.song else {
                self.numberLabel.text = nil
                self.titleLabel.text = state.songs.isEmpty ? String(localized: "roulette.empty") : String(localized: "roulette.retry")
                self.singerLabel.text = nil
                self.memoRow.isHidden = true
                self.statusLabel.text = nil
                return
            }
            self.numberLabel.text = "\(song.brand.name) · \(song.no)"
            self.titleLabel.text = song.title
            self.singerLabel.text = song.singer
            self.memoLabel.text = song.memo
            self.memoLabel.numberOfLines = 1
            self.memoRow.isHidden = song.memo?.isEmpty != false
            self.statusLabel.text = state.remaining.isEmpty ? String(localized: "roulette.cycleComplete") : String(localized: "roulette.exclusionHint")
            if !UIAccessibility.isReduceMotionEnabled {
                UIView.transition(with: self.numberLabel, duration: 0.2, options: .transitionCrossDissolve, animations: nil)
            }
        }).disposed(by: disposeBag)
    }
}
