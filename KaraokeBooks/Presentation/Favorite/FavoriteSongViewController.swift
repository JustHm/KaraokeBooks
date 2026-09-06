//
//  FavoriteSongViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/12.
//

import UIKit
import SnapKit
import ReactorKit
import RxCocoa

final class FavoriteSongViewController: UIViewController, View {
    typealias Reactor = FavoriteSongReactor
    var disposeBag = DisposeBag()
    private var bannerHeightConstraint: Constraint?
    private let songPager = BrandSongPagerViewController(emptyMessage: String(localized: "favorite.empty"))
    private lazy var brandSegmentedControl: ClearSegmentedControl = {
        let control = ClearSegmentedControl()
        for (index, brand) in BrandType.allCases.enumerated() {
            control.insertSegment(withTitle: brand.name, at: index, animated: false)
        }
        control.selectedSegmentIndex = 0
        return control
    }()
    private let bannerContainerView = BottomBannerAdView()
    private lazy var removeSelectedButton = UIBarButtonItem(
        title: String(localized: "favorite.remove"),
        style: .plain,
        target: self,
        action: #selector(didTapRemoveSelected)
    )

    private lazy var rouletteButton = UIBarButtonItem(image: UIImage(systemName: "dice"), style: .plain, target: self, action: #selector(showRoulette))
    private lazy var selectionEditButton = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(toggleSelectionEditing))

    init(reactor: Reactor) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bannerContainerView.load(rootViewController: self)
        navigationItem.largeTitleDisplayMode = .never
        rouletteButton.accessibilityLabel = String(localized: "accessibility.roulette")
        selectionEditButton.accessibilityLabel = String(localized: "accessibility.favoriteEdit")
        navigationItem.rightBarButtonItems = [selectionEditButton, rouletteButton]
        toolbarItems = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            removeSelectedButton,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        ]
        removeSelectedButton.tintColor = .systemRed
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reactor?.action.onNext(.reload)
    }

    func bind(reactor: FavoriteSongReactor) {
        brandSegmentedControl.rx.selectedSegmentIndex
            .map { Reactor.Action.brandType(BrandType.allCases[$0]) }
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
        songPager.selectedSongsChanged
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind { owner, songs in
                owner.updateRemoveSelectedButton(songs: songs)
            }
            .disposed(by: disposeBag)
        reactor.state.observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind { owner, state in
                for brand in BrandType.allCases {
                    owner.songPager.render(state.page(for: brand), for: brand)
                }
                let hasFavorites = BrandType.allCases.contains { !state.page(for: $0).songs.isEmpty }
                owner.selectionEditButton.isEnabled = hasFavorites
                owner.rouletteButton.isEnabled = !state.favoriteSongs.isEmpty
                if !hasFavorites, owner.isEditing {
                    owner.setEditing(false, animated: true)
                }
            }
            .disposed(by: disposeBag)
        reactor.state.map { $0.currentBrand }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind { owner, brand in
                owner.brandSegmentedControl.selectedSegmentIndex = BrandType.allCases.firstIndex(of: brand) ?? 0
                owner.songPager.select(brand)
            }
            .disposed(by: disposeBag)
        reactor.state.compactMap { $0.selectedSong }
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind { owner, song in
                owner.present(SongDetailViewController(reactor: SongDetailReactor(song: song)), animated: true)
            }
            .disposed(by: disposeBag)
    }

    private func setupViews() {
        view.backgroundColor = .customBackground
        navigationItem.title = HomeList.favourite.localizedTitle
        [brandSegmentedControl, bannerContainerView].forEach { view.addSubview($0) }
        addChild(songPager)
        view.addSubview(songPager.view)
        songPager.didMove(toParent: self)
        brandSegmentedControl.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(8.0)
            $0.left.right.equalToSuperview().inset(32.0)
        }
        songPager.view.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(bannerContainerView.snp.top)
            $0.top.equalTo(brandSegmentedControl.snp.bottom).offset(2.0)
        }
        bannerContainerView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            self.bannerHeightConstraint = $0.height.equalTo(0.0).constraint
        }
        bannerContainerView.onHeightChanged = { [weak self] height in
            self?.bannerHeightConstraint?.update(offset: height)
            self?.view.layoutIfNeeded()
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        selectionEditButton.image = UIImage(systemName: editing ? "checkmark" : "square.and.pencil")
        selectionEditButton.accessibilityLabel = editing ? String(localized: "accessibility.editDone") : String(localized: "accessibility.favoriteEdit")
        navigationItem.rightBarButtonItems = editing ? [selectionEditButton] : [selectionEditButton, rouletteButton]
        songPager.setTableEditing(editing, animated: animated)
        navigationController?.setToolbarHidden(!editing, animated: animated)
        updateRemoveSelectedButton(songs: songPager.selectedSongs)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: animated)
    }

    private func updateRemoveSelectedButton(songs: [Song]) {
        removeSelectedButton.isEnabled = !songs.isEmpty
        removeSelectedButton.title = songs.isEmpty
            ? String(localized: "favorite.remove")
            : "\(String(localized: "favorite.remove")) (\(songs.count))"
    }

    @objc private func toggleSelectionEditing() {
        setEditing(!isEditing, animated: true)
    }

    @objc private func showRoulette() {
        guard !isEditing, let songs = reactor?.currentState.favoriteSongs, !songs.isEmpty else { return }
        present(FavoriteRouletteViewController(reactor: FavoriteRouletteReactor(songs: songs)), animated: true)
    }

    @objc private func didTapRemoveSelected() {
        let songs = songPager.selectedSongs
        guard !songs.isEmpty, let reactor else { return }
        setEditing(false, animated: true)
        reactor.action.onNext(.deleteSongs(songs))
    }
}
