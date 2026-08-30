//
//  FavoriteSongViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/12.
//

import UIKit
import SnapKit
import ReactorKit
import GoogleMobileAds

final class FavoriteSongViewController: UIViewController, View {
    typealias Reactor = FavoriteSongReactor
    var disposeBag = DisposeBag()
    private var bannerHeightConstraint: Constraint?
    private var nativeAdLoader: AdLoader?
    private var nativeAd: NativeAd?
    private var nativeAdRetryWorkItem: DispatchWorkItem?
    private var hasRetriedNativeAd = false
    private var shouldShowNativeAd = false
    
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
        return tableView
    }()
    private lazy var warningText: UILabel = {
        let label = UILabel()
        label.text = "저장한 애창곡이 없습니다."
        label.font = .systemFont(ofSize: 16.0, weight: .medium)
        label.textColor = .customPrimaryText
        label.isHidden = true
        return label
    }()
    private lazy var bannerContainerView = BottomBannerAdView()
    private lazy var nativeAdCardView = NativeAdCardView()
    
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
        if shouldShowNativeAd {
            loadNativeAd()
        }
    }
    
    func bind(reactor: FavoriteSongReactor) {
        brandSegmentedControl.rx.selectedSegmentIndex
            .map{Reactor.Action.brandType(BrandType.allCases[$0])}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        favoriteSongTableView.rx.itemSelected
            .map{Reactor.Action.songDetail($0)}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        favoriteSongTableView.rx.itemDeleted
            .map{Reactor.Action.deleteSong($0)}
            .bind(to: reactor.action)
            .disposed(by:disposeBag)
        
        //State
        reactor.state.observe(on: MainScheduler.instance)
            .map {$0.favoriteSongs}
            .do(onNext: { [weak self] songs in
                self?.updateNativeAdVisibility(hasResults: !songs.isEmpty)
            })
            .bind(to: favoriteSongTableView.rx.items(cellIdentifier: SongTableViewCell.identifier, cellType: SongTableViewCell.self)) { index, item, cell in
                cell.setup(rank: index, song: item)
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
                owner.showAlert(header: "Error", body: msg)
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
        navigationItem.title = HomeList.favourite.rawValue
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
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true)
    }

    private func updateNativeAdVisibility(hasResults: Bool) {
        shouldShowNativeAd = hasResults
        guard hasResults else {
            nativeAdRetryWorkItem?.cancel()
            nativeAdRetryWorkItem = nil
            hasRetriedNativeAd = false
            favoriteSongTableView.tableHeaderView = nil
            return
        }

        if let nativeAd {
            showNativeAd(nativeAd)
        } else {
            loadNativeAd()
        }
    }

    private func loadNativeAd() {
        guard nativeAdLoader == nil,
              nativeAd == nil,
              let adUnitID = nativeAdUnitID else { return }

        let loader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: self,
            adTypes: [.native],
            options: nil
        )
        loader.delegate = self
        nativeAdLoader = loader
        loader.load(Request())
    }

    private func scheduleNativeAdRetry() {
        guard shouldShowNativeAd,
              !hasRetriedNativeAd,
              nativeAd == nil else { return }

        hasRetriedNativeAd = true
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.shouldShowNativeAd else { return }
            self.nativeAdRetryWorkItem = nil
            self.loadNativeAd()
        }
        nativeAdRetryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0, execute: workItem)
    }

    private func showNativeAd(_ nativeAd: NativeAd) {
        guard shouldShowNativeAd else { return }

        nativeAdCardView.populate(with: nativeAd)
        view.layoutIfNeeded()
        nativeAdCardView.sizeToFit(width: favoriteSongTableView.bounds.width)
        favoriteSongTableView.tableHeaderView = nativeAdCardView
        nativeAdCardView.associate(with: nativeAd)
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

extension FavoriteSongViewController: NativeAdLoaderDelegate, AdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        nativeAd.delegate = self
        self.nativeAd = nativeAd
        showNativeAd(nativeAd)
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        nativeAdLoader = nil
        scheduleNativeAdRetry()
    }

    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        nativeAdLoader = nil
    }
}

extension FavoriteSongViewController: NativeAdDelegate {}
