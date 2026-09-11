//
//  HomeViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import UIKit
import SnapKit
import RxCocoa
import ReactorKit

final class HomeViewController: UIViewController, View {
    typealias Reactor = HomeReactor

    private let contactEmail = "taggma12@icloud.com"
    private var actionStackHeightConstraint: Constraint?
    private let songPager = BrandSongPagerViewController()
    
    var disposeBag = DisposeBag()

    private lazy var helpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "questionmark.circle.fill"), for: .normal)
        button.tintColor = .customPrimaryText
        button.accessibilityLabel = String(localized: "accessibility.contact")
        return button
    }()

    private lazy var appIconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "HomeAppIcon"))
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8.0
        imageView.clipsToBounds = true
        imageView.isAccessibilityElement = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "app.title")
        label.font = UIFontMetrics(forTextStyle: .title1).scaledFont(
            for: .systemFont(ofSize: 30.0, weight: .bold)
        )
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .customPrimaryText
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var brandStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [appIconImageView, titleLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 10.0
        return stack
    }()

    private lazy var headerStackView: UIStackView = {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [brandStackView, spacer, helpButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 10.0
        return stack
    }()
    
    private lazy var stackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.distribution = .fillEqually
        return stack
    }()
    
    private lazy var favoriteListButton: MoveSceneButton = {
        let button = MoveSceneButton(title: String(localized: "favorite.title"), symbol: "star")
        return button
    }()
    
    private lazy var searchButton: MoveSceneButton = {
        let button = MoveSceneButton(title: String(localized: "home.searchSongs"), symbol: "magnifyingglass")
        return button
    }()
    
    private lazy var rankTableHeader = RankTableViewHeader()
    
    private lazy var brandSegmentedControl: ClearSegmentedControl = {
        let segmentedControl = ClearSegmentedControl()
        BrandType.allCases.enumerated().forEach { (index, value) in
            segmentedControl.insertSegment(
                withTitle: value.name,
                at: index,
                animated: false)
        }
        segmentedControl.selectedSegmentIndex = 0
        return segmentedControl
    }()
    
    init(reactor: Reactor) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        if let reactor,
           reactor.currentState.popularList.isEmpty,
           !reactor.currentState.isLoading {
            reactor.action.onNext(.rankDateType(reactor.currentState.dateType))
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory else { return }
        updateActionStackLayout()
    }
}

extension HomeViewController {
    func setupViews() {
        [favoriteListButton, searchButton].forEach { stackView.addArrangedSubview($0) }
        helpButton.addTarget(self, action: #selector(didTapHelp), for: .touchUpInside)
        [headerStackView, stackView, rankTableHeader, brandSegmentedControl].forEach {
            view.addSubview($0)
        }

        headerStackView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(12.0)
            $0.left.right.equalToSuperview().inset(20.0)
        }

        appIconImageView.snp.makeConstraints {
            $0.size.equalTo(32.0)
        }

        helpButton.snp.makeConstraints {
            $0.size.equalTo(44.0)
        }
        
        stackView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16.0)
            $0.top.equalTo(headerStackView.snp.bottom).offset(16.0)
            self.actionStackHeightConstraint = $0.height.equalTo(84.0).constraint
        }
        
        rankTableHeader.snp.makeConstraints {
            $0.top.equalTo(stackView.snp.bottom).offset(16.0)
            $0.left.right.equalToSuperview().inset(32.0)
        }
        
        brandSegmentedControl.snp.makeConstraints {
            $0.top.equalTo(rankTableHeader.snp.bottom)
            $0.left.right.equalToSuperview().inset(32.0)
        }
        
        addChild(songPager)
        view.addSubview(songPager.view)
        songPager.didMove(toParent: self)
        songPager.view.snp.makeConstraints {
            $0.top.equalTo(brandSegmentedControl.snp.bottom).offset(2.0)
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        updateActionStackLayout()
    }

    @objc private func didTapHelp() {
        present(ContactSheetViewController(email: contactEmail), animated: true)
    }

}

extension HomeViewController {
    private func updateActionStackLayout() {
        let usesAccessibilityLayout = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        stackView.axis = usesAccessibilityLayout ? .vertical : .horizontal
        stackView.spacing = usesAccessibilityLayout ? 8.0 : 16.0
        actionStackHeightConstraint?.update(offset: usesAccessibilityLayout ? 112.0 : 84.0)
    }

    func bind(reactor: HomeReactor) {
        //Action
        brandSegmentedControl.rx.selectedSegmentIndex
            .map{Reactor.Action.brandType(BrandType.allCases[$0])}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        songPager.selectedBrand
            .map(Reactor.Action.brandType)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        songPager.selectedSong
            .map(Reactor.Action.songDetail)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        rankTableHeader.currentDate
            .map {Reactor.Action.rankDateType($0)}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        favoriteListButton.rx.tap
            .withUnretained(self)
            .bind { owner, _ in
                let reactor = FavoriteSongReactor()
                let vc = FavoriteSongViewController(reactor: reactor)
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        searchButton.rx.tap
            .withUnretained(self)
            .bind { owner, _ in
                let reactor = SearchResultReactor()
                let vc = SearchResultViewController(reactor: reactor)
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        //State
        reactor.state.observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind { owner, state in
                for brand in BrandType.allCases {
                    owner.songPager.render(state.page(for: brand), for: brand)
                }
            }
            .disposed(by: disposeBag)
        reactor.state.map { $0.brandType }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind { owner, brand in
                owner.brandSegmentedControl.selectedSegmentIndex = BrandType.allCases.firstIndex(of: brand) ?? 0
                owner.songPager.select(brand)
            }
            .disposed(by: disposeBag)
        reactor.state.compactMap{$0.selectedSong}
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind { owner, song in
                if let detailReactor = reactor.reactorForSetting(song: song) {
                    let songDetailVC = SongDetailViewController(reactor: detailReactor)
                    owner.present(songDetailVC, animated: true)
                }
            }
            .disposed(by: disposeBag)
    }

    private func showAlert(header: String, body: String) {
        let alert = UIAlertController(title: header, message: body, preferredStyle: .alert)
        let action = UIAlertAction(title: String(localized: "action.ok"), style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true)
    }
}

private final class ContactSheetViewController: UIViewController {
    private let email: String
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "contact.title")
        label.font = .preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = .customPrimaryText
        return label
    }()

    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.text = email
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var openMailButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "envelope.fill"), for: .normal)
        button.setTitle("  " + String(localized: "action.openMail"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.backgroundColor = .systemPink
        button.layer.cornerRadius = 12.0
        button.addTarget(self, action: #selector(didTapOpenMail), for: .touchUpInside)
        return button
    }()

    private lazy var copyEmailButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        button.setTitle("  " + String(localized: "action.copyEmail"), for: .normal)
        button.setTitleColor(.customPrimaryText, for: .normal)
        button.tintColor = .customPrimaryText
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.backgroundColor = .tertiarySystemFill
        button.layer.cornerRadius = 12.0
        button.addTarget(self, action: #selector(didTapCopyEmail), for: .touchUpInside)
        return button
    }()

    init(email: String) {
        self.email = email
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        preferredContentSize = CGSize(width: 0, height: 280.0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSheet()
        setupViews()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            configureSheet()
        }
    }

    private func configureSheet() {
        guard #available(iOS 15.0, *), let sheet = sheetPresentationController else { return }

        let contactDetentIdentifier = UISheetPresentationController.Detent.Identifier("contact")
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            sheet.detents = [.large()]
            sheet.selectedDetentIdentifier = .large
        } else if #available(iOS 16.0, *) {
            sheet.detents = [
                .custom(identifier: contactDetentIdentifier) { context in
                    min(280.0, context.maximumDetentValue)
                },
                .large()
            ]
            sheet.selectedDetentIdentifier = contactDetentIdentifier
        } else {
            sheet.detents = [.medium(), .large()]
            sheet.selectedDetentIdentifier = .medium
        }
        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = 24.0
    }

    private func setupViews() {
        view.backgroundColor = .customForeground
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        scrollView.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = 10
        [titleLabel, emailLabel, openMailButton, copyEmailButton].forEach {
            contentStack.addArrangedSubview($0)
        }
        contentStack.setCustomSpacing(6, after: titleLabel)
        contentStack.setCustomSpacing(22, after: emailLabel)
        contentStack.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide).inset(20)
            $0.width.equalTo(scrollView.frameLayoutGuide).offset(-40)
        }
        [openMailButton, copyEmailButton].forEach { button in
            button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(52) }
        }
    }

    @objc private func didTapOpenMail() {
        guard let url = URL(string: "mailto:\(email)") else { return }
        UIApplication.shared.open(url)
    }

    @objc private func didTapCopyEmail() {
        UIPasteboard.general.string = email
        copyEmailButton.setTitle("  " + String(localized: "action.copied"), for: .normal)
    }
}
