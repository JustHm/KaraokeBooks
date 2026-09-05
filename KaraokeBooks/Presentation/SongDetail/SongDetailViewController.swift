//
//  SongDetailViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/10.
//

import UIKit
import SnapKit
import ReactorKit
import RxSwift
import SafariServices

final class SongDetailViewController: UIViewController, View {
    var disposeBag = DisposeBag()
    typealias Reactor = SongDetailReactor
    private lazy var titleImage: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "music.note.house"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemPink
        imageView.clipsToBounds = true
        return imageView
    }()
    private lazy var songInfoStackView: SongInfoStackView = {
        let stackView = SongInfoStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8.0
        stackView.distribution = .fill
        stackView.setContentHuggingPriority(.required, for: .vertical)
        return stackView
    }()
    private lazy var youtubeLinkButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "play.rectangle.fill")
        button.setImage(image, for: .normal)
        button.setTitle("  " + String(localized: "action.showYouTube"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 12.0
        return button
    }()
    private lazy var starButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "star")
        button.setImage(image, for: .normal)
        button.setTitle("  " + String(localized: "favorite.add"), for: .normal)
        button.setTitleColor(.customPrimaryText, for: .normal)
        button.tintColor = .systemYellow
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = .customBackground
        button.layer.cornerRadius = 12.0
        return button
    }()
    private lazy var interactionButtonStackView: UIStackView = {
        let stackView = UIStackView(
            arrangedSubviews: [youtubeLinkButton, starButton]
        )
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12.0
        return stackView
    }()
    
    init(reactor: Reactor) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
        modalPresentationStyle = .pageSheet
        preferredContentSize = CGSize(width: 0, height: 420.0)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSheet()
        setupViews()
        reactor?.action.onNext(.viewDidLoad)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory else { return }
        updateInteractionLayout()
        configureSheet()
    }
    func bind(reactor: SongDetailReactor) {
        starButton.rx.tap
            .map{ Reactor.Action.starTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        youtubeLinkButton.rx.tap
            .map{ Reactor.Action.youtubeTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        reactor.state.map{$0.isStar}
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind { owner, isStar in
                let symbol = isStar ? "star.fill" : "star"
                let favoriteTitle = isStar
                    ? String(localized: "favorite.remove")
                    : String(localized: "favorite.add")
                owner.starButton.setImage(UIImage(systemName: symbol), for: .normal)
                owner.starButton.setTitle("  " + favoriteTitle, for: .normal)
                owner.starButton.accessibilityLabel = favoriteTitle
                owner.starButton.accessibilityTraits = isStar ? [.button, .selected] : .button
            }
            .disposed(by: disposeBag)
        reactor.pulse(\.$youtubeURL)
            .compactMap { $0 }
            .withUnretained(self)
            .bind { owner, url in
                MRSearchInterstitialAdController.shared.presentIfEligible(from: owner) {
                    let viewController = SFSafariViewController(url: url.absoluteURL)
                    owner.present(viewController, animated: true)
                }
            }
            .disposed(by: disposeBag)
        reactor.state.map{$0.errorMessage}
            .compactMap{$0} //compactMap은 nil만 필터링 하기 때문에 두 번 호출되지 않음.
            .withUnretained(self)
            .bind { owner, msg in
                owner.showAlert(header: String(localized: "alert.errorTitle"), body: msg)
            }
            .disposed(by: disposeBag)
        reactor.state.map{$0.song}
            .distinctUntilChanged()
            .withUnretained(self)
            .bind { owner, song in
                owner.songInfoStackView.setupLabelText(song: song)
            }
            .disposed(by: disposeBag)
    }
}

extension SongDetailViewController {
    private func configureSheet() {
        guard #available(iOS 15.0, *), let sheet = sheetPresentationController else { return }

        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            sheet.detents = [.large()]
            sheet.selectedDetentIdentifier = .large
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24.0
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            return
        }

        let compactDetentIdentifier = UISheetPresentationController.Detent.Identifier("songDetail")
        if #available(iOS 16.0, *) {
            sheet.detents = [
                .custom(identifier: compactDetentIdentifier) { context in
                    min(420.0, context.maximumDetentValue)
                }
            ]
            sheet.selectedDetentIdentifier = compactDetentIdentifier
        } else {
            sheet.detents = [.medium()]
            sheet.selectedDetentIdentifier = .medium
        }
        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = 24.0
        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
    }

    private func setupViews() {
        view.backgroundColor = .customForeground
        [
            titleImage,
            songInfoStackView,
            interactionButtonStackView
        ].forEach {
            view.addSubview($0)
        }
        titleImage.snp.makeConstraints {
            $0.size.equalTo(32.0)
            $0.top.left.equalToSuperview().inset(16.0)
        }
        songInfoStackView.snp.makeConstraints {
            $0.top.equalTo(titleImage.snp.bottom).offset(16.0)
            $0.left.right.equalToSuperview().inset(16.0)
        }
        interactionButtonStackView.snp.makeConstraints {
            $0.top.greaterThanOrEqualTo(songInfoStackView.snp.bottom).offset(20.0)
            $0.left.right.equalToSuperview().inset(16.0)
            $0.height.greaterThanOrEqualTo(48.0)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16.0)
        }
        updateInteractionLayout()
    }

    private func updateInteractionLayout() {
        let usesAccessibilityLayout = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        interactionButtonStackView.axis = usesAccessibilityLayout ? .vertical : .horizontal
        interactionButtonStackView.spacing = usesAccessibilityLayout ? 8.0 : 12.0
    }
    private func showAlert(header: String, body: String) {
        let alert = UIAlertController(title: header, message: body, preferredStyle: .alert)
        let action = UIAlertAction(title: String(localized: "action.ok"), style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true)
    }
}
