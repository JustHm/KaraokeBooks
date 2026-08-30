//
//  SearchResultViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/16.
//

import UIKit
import SnapKit
import ReactorKit
import GoogleMobileAds

final class SearchResultViewController: UIViewController, View {
    typealias Reactor = SearchResultReactor
    var disposeBag = DisposeBag()

    private var selectedSearchScope = SearchScopeType.title
    private var selectedBrand = BrandType.tj
    private var bannerHeightConstraint: Constraint?
    private var nativeAdLoader: AdLoader?
    private var nativeAd: NativeAd?
    private var nativeAdRetryWorkItem: DispatchWorkItem?
    private var hasRetriedNativeAd = false
    private var shouldShowNativeAd = false

    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = SearchScopeType.title.name
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()
    private lazy var filterTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "필터"
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        return label
    }()
    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "line.3.horizontal.decrease.circle"), for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.tintColor = .systemBlue
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = .tertiarySystemFill
        button.layer.cornerRadius = 12.0
        button.contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 16.0, bottom: 0.0, right: 16.0)
        button.semanticContentAttribute = .forceRightToLeft
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    private lazy var searchResultTableView: SongTableView = {
        let tableView = SongTableView(frame: .zero, style: .plain)
        tableView.register(SongTableViewCell.self, forCellReuseIdentifier: SongTableViewCell.identifier)
        return tableView
    }()
    private lazy var warningText: UILabel = {
        let label = UILabel()
        label.text = "검색 결과가 없습니다."
        label.font = .systemFont(ofSize: 16.0, weight: .medium)
        label.textColor = .customPrimaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    private lazy var loadIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .customPrimaryText
        indicator.isHidden = true
        indicator.startAnimating()
        return indicator
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
        setupNavigationBar()
        setupViews()
        bannerContainerView.load(rootViewController: self)
        searchBar.searchTextField.addTarget(
            self,
            action: #selector(searchTextFieldDidSubmit),
            for: .editingDidEndOnExit
        )
        updateFilterMenu()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldShowNativeAd {
            loadNativeAd()
        }
    }
    
    func bind(reactor: SearchResultReactor) {
        searchResultTableView.rx.itemSelected
            .map{Reactor.Action.songDetail($0)}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
//        searchResultTableView.rx.prefetchRows
//            .flatMap{Observable.from($0)}
//            .map{ Reactor.Action.currentRow($0)}
//            .bind(to: reactor.action)
//            .disposed(by: disposeBag)
        searchBar.rx.value
            .distinctUntilChanged()
            .debounce(RxTimeInterval.milliseconds(150), scheduler: MainScheduler.instance)
            .map{
                let query = $0 == "" ? nil : $0
                return Reactor.Action.searchQuery(query)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        
        reactor.state.map{$0.songs}
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .do(onNext: { [weak self] songs in
                self?.updateNativeAdVisibility(hasResults: !songs.isEmpty)
            })
            .bind(to: searchResultTableView.rx.items(cellIdentifier: SongTableViewCell.identifier, cellType: SongTableViewCell.self)) { index, item, cell in
                cell.setup(rank: index, song: item)
            }
            .disposed(by: disposeBag)
        reactor.state.map { state -> String? in
            if let errorDescription = state.errorDescription {
                return errorDescription
            }
            return state.hasCompletedSearch && state.isEmpty ? "검색 결과가 없습니다." : nil
        }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind { owner, message in
                owner.warningText.text = message
                owner.warningText.isHidden = message == nil
            }
            .disposed(by: disposeBag)
        reactor.state.compactMap{$0.selectedSong}
            .withUnretained(self)
            .bind { owner, song in
                if let detailReactor = reactor.reactorForSetting(song: song) {
                    let songDetailVC = SongDetailViewController(reactor: detailReactor)
                    owner.present(songDetailVC, animated: true)
                }
            }
            .disposed(by: disposeBag)
        reactor.state.observe(on: MainScheduler.instance)
            .map{$0.isLoading}
            .distinctUntilChanged()
            .withUnretained(self)
            .bind { owner, isLoading in
                owner.loadIndicator.isHidden = !isLoading
                isLoading ? owner.loadIndicator.startAnimating() : owner.loadIndicator.stopAnimating()
            }
            .disposed(by: disposeBag)
        reactor.state.map { $0.brandType }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind { owner, brand in
                owner.selectedBrand = brand
                owner.updateFilterMenu()
            }
            .disposed(by: disposeBag)
        reactor.state.map { $0.searchType }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind { owner, type in
                owner.selectedSearchScope = type == .title ? .title : .singer
                owner.updateFilterMenu()
            }
            .disposed(by: disposeBag)
    }
}

extension SearchResultViewController {
    func setupViews() {
        view.backgroundColor = .customBackground
        
        [searchBar, filterTitleLabel, filterButton, searchResultTableView, bannerContainerView, warningText, loadIndicator].forEach {
            view.addSubview($0)
        }
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(8.0)
            $0.left.right.equalToSuperview().inset(16.0)
        }
        filterButton.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(8.0)
            $0.right.equalToSuperview().inset(16.0)
            $0.height.equalTo(40.0)
        }
        filterTitleLabel.snp.makeConstraints {
            $0.centerY.equalTo(filterButton)
            $0.right.equalTo(filterButton.snp.left).offset(-12.0)
            $0.left.greaterThanOrEqualToSuperview().inset(16.0)
        }
        searchResultTableView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(filterButton.snp.bottom).offset(8.0)
            $0.bottom.equalTo(bannerContainerView.snp.top)
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
            $0.left.right.equalToSuperview().inset(24.0)
        }
        loadIndicator.snp.makeConstraints {
            $0.center.equalTo(searchResultTableView)
        }
    }
    func setupNavigationBar() {
        navigationItem.title = SearchScopeType.title.name
        navigationItem.largeTitleDisplayMode = .never
    }

    private func updateFilterMenu() {
        let scopeActions = SearchScopeType.allCases.map { scope in
            UIAction(
                title: scope.name,
                state: scope == selectedSearchScope ? .on : .off
            ) { [weak self] _ in
                self?.changeSearchScope(scope)
            }
        }
        let brandActions = BrandType.allCases.map { brand in
            UIAction(
                title: brand.name,
                state: brand == selectedBrand ? .on : .off
            ) { [weak self] _ in
                self?.changeBrand(brand)
            }
        }
        filterButton.menu = UIMenu(children: [
            UIMenu(title: "검색 기준", options: .displayInline, children: scopeActions),
            UIMenu(title: "서비스", options: .displayInline, children: brandActions)
        ])
        filterButton.setTitle(
            "\(selectedSearchScope.name) · \(selectedBrand.name)  ",
            for: .normal
        )
    }

    private func changeSearchScope(_ scope: SearchScopeType) {
        guard scope != selectedSearchScope else { return }
        reactor?.action.onNext(.searchType(scope))
        reactor?.action.onNext(.search(searchBar.text))
    }

    private func changeBrand(_ brand: BrandType) {
        guard brand != selectedBrand else { return }
        reactor?.action.onNext(.brandType(brand))
        reactor?.action.onNext(.search(searchBar.text))
    }
    private func showAlert(header: String, body: String) {
        let alert = UIAlertController(title: header, message: body, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true)
    }

    @objc private func searchTextFieldDidSubmit() {
        view.endEditing(true)
        reactor?.action.onNext(.search(searchBar.text))
    }

    private func updateNativeAdVisibility(hasResults: Bool) {
        shouldShowNativeAd = hasResults
        guard hasResults else {
            nativeAdRetryWorkItem?.cancel()
            nativeAdRetryWorkItem = nil
            hasRetriedNativeAd = false
            searchResultTableView.tableHeaderView = nil
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
        nativeAdCardView.sizeToFit(width: searchResultTableView.bounds.width)
        searchResultTableView.tableHeaderView = nativeAdCardView
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

extension SearchResultViewController: NativeAdLoaderDelegate, AdLoaderDelegate {
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

extension SearchResultViewController: NativeAdDelegate {}
