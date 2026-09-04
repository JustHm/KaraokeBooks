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
    private var favoriteSongs: [Song] = []
    private let displayItems = BehaviorRelay<[SongListDisplayItem]>(value: [])
    
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
    private lazy var favoriteSongTableView: SongTableView = {
        let tableView = SongTableView(frame: .zero, style: .plain)
        tableView.register(SongTableViewCell.self,
                           forCellReuseIdentifier: SongTableViewCell.identifier)
        tableView.register(
            NativeAdTableViewCell.self,
            forCellReuseIdentifier: NativeAdTableViewCell.identifier
        )
        return tableView
    }()
    private lazy var warningText: UILabel = {
        let label = UILabel()
        label.text = String(localized: "favorite.empty")
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .customPrimaryText
        label.isHidden = true
        return label
    }()
    private lazy var bannerContainerView = BottomBannerAdView()
    private lazy var nativeAdPlacement: NativeAdPlacementController = {
        let placement = NativeAdPlacementController(rootViewController: self)
        placement.onAvailabilityChanged = { [weak self] in
            self?.updateDisplayItems()
        }
        return placement
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
        bannerContainerView.load(rootViewController: self)
        navigationItem.largeTitleDisplayMode = .never
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        nativeAdPlacement.loadIfNeeded()
    }
    
    func bind(reactor: FavoriteSongReactor) {
        brandSegmentedControl.rx.selectedSegmentIndex
            .map{Reactor.Action.brandType(BrandType.allCases[$0])}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        favoriteSongTableView.rx.itemSelected
            .withLatestFrom(displayItems) { ($0, $1) }
            .compactMap { indexPath, items in
                guard items.indices.contains(indexPath.row) else { return nil }
                return items[indexPath.row].song
            }
            .map(Reactor.Action.songDetail)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        favoriteSongTableView.rx.itemDeleted
            .withLatestFrom(displayItems) { ($0, $1) }
            .compactMap { indexPath, items in
                guard items.indices.contains(indexPath.row) else { return nil }
                return items[indexPath.row].song
            }
            .map(Reactor.Action.deleteSong)
            .bind(to: reactor.action)
            .disposed(by:disposeBag)
        favoriteSongTableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        //State
        displayItems
            .bind(to: favoriteSongTableView.rx.items) { [weak self] tableView, _, item in
                switch item {
                case let .song(song, rank):
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: SongTableViewCell.identifier
                    ) as! SongTableViewCell
                    cell.setup(rank: rank, song: song)
                    return cell
                case let .nativeAd(slot):
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: NativeAdTableViewCell.identifier
                    ) as! NativeAdTableViewCell
                    self?.nativeAdPlacement.configure(cell, slot: slot)
                    return cell
                }
            }
            .disposed(by: disposeBag)
        reactor.state.observe(on: MainScheduler.instance)
            .map { $0.favoriteSongs }
            .distinctUntilChanged()
            .withUnretained(self)
            .bind { owner, songs in
                owner.favoriteSongs = songs
                owner.updateNativeAdVisibility(songs: songs)
                owner.updateDisplayItems()
            }
            .disposed(by: disposeBag)
        reactor.state.map{!$0.isEmpty}
            .distinctUntilChanged()
            .bind(to: warningText.rx.isHidden)
            .disposed(by: disposeBag)
        reactor.state.map {$0.errorDescription}
            .compactMap{$0} //compactMap은 nil만 필터링 하기 때문에 두 번 호출되지 않음.
            .withUnretained(self)
            .bind { owner, msg in
                owner.showAlert(header: String(localized: "alert.errorTitle"), body: msg)
            }
            .disposed(by: disposeBag)
        reactor.state.compactMap{$0.selectedSong}
            .withUnretained(self)
            .bind { owner, song in
                if let detailReactor = reactor.reactorForSetting() {
                    let songDetailVC = SongDetailViewController(reactor: detailReactor)
                    owner.present(songDetailVC, animated: true)
                }
            }
            .disposed(by: disposeBag)
    }
}


extension FavoriteSongViewController {
    func setupViews() {
        view.backgroundColor = .customBackground
        navigationItem.title = HomeList.favourite.localizedTitle
        [favoriteSongTableView, brandSegmentedControl, bannerContainerView, warningText].forEach {
            view.addSubview($0)
        }
        brandSegmentedControl.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(8.0)
            $0.left.right.equalToSuperview().inset(32.0)
        }
        favoriteSongTableView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16.0)
            $0.bottom.equalTo(bannerContainerView.snp.top)
            $0.top.equalTo(brandSegmentedControl.snp.bottom).offset(8.0)
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
        warningText.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    private func showAlert(header: String, body: String) {
        let alert = UIAlertController(title: header, message: body, preferredStyle: .alert)
        let action = UIAlertAction(title: String(localized: "action.ok"), style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true)
    }

    private func updateNativeAdVisibility(songs: [Song]) {
        nativeAdPlacement.setEnabled(
            !songs.isEmpty,
            desiredAdCount: songs.nativeAdSlotCount
        )
    }

    private func updateDisplayItems() {
        displayItems.accept(
            favoriteSongs.displayItems(nativeAdCount: nativeAdPlacement.availableAdCount)
        )
    }
}

extension FavoriteSongViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard displayItems.value.indices.contains(indexPath.row),
              displayItems.value[indexPath.row].song != nil else { return .none }
        return .delete
    }
}
