//
//  SearchResultViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/16.
//

import UIKit
import SnapKit
import ReactorKit
import RxCocoa

final class SearchResultViewController: UIViewController, View, UITableViewDataSourcePrefetching {
    typealias Reactor = SearchResultReactor
    var disposeBag = DisposeBag()

    private var selectedSearchScope = SearchScopeType.title
    private var selectedBrand = BrandType.tj
    private var bannerHeightConstraint: Constraint?
    private var songs: [Song] = []
    private let displayItems = BehaviorRelay<[SongListDisplayItem]>(value: [])

    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = SearchScopeType.title.localizedTitle
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()
    private lazy var filterTitleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "search.filter")
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        return label
    }()
    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "line.3.horizontal.decrease.circle")
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 8.0
        configuration.baseForegroundColor = .systemBlue
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 0.0,
            leading: 16.0,
            bottom: 0.0,
            trailing: 16.0
        )
        button.configuration = configuration
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = .tertiarySystemFill
        button.layer.cornerRadius = 12.0
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    private lazy var searchResultTableView: SongTableView = {
        let tableView = SongTableView(frame: .zero, style: .plain)
        tableView.register(SongTableViewCell.self, forCellReuseIdentifier: SongTableViewCell.identifier)
        tableView.register(
            NativeAdTableViewCell.self,
            forCellReuseIdentifier: NativeAdTableViewCell.identifier
        )
        return tableView
    }()
    private lazy var warningText: UILabel = {
        let label = UILabel()
        label.text = String(localized: "search.empty")
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
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
        setupNavigationBar()
        setupViews()
        searchResultTableView.prefetchDataSource = self
        searchBar.searchTextField.addTarget(
            self,
            action: #selector(searchTextFieldDidSubmit),
            for: .editingDidEndOnExit
        )
        updateFilterMenu()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        nativeAdPlacement.loadIfNeeded()
    }
    
    func bind(reactor: SearchResultReactor) {
        searchResultTableView.rx.itemSelected
            .withLatestFrom(displayItems) { ($0, $1) }
            .compactMap { indexPath, items in
                guard items.indices.contains(indexPath.row) else { return nil }
                return items[indexPath.row].song
            }
            .map(Reactor.Action.songDetail)
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
        
        
        displayItems
            .bind(to: searchResultTableView.rx.items) { [weak self] tableView, _, item in
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
        reactor.state.map{$0.songs}
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind { owner, songs in
                owner.songs = songs
                owner.updateNativeAdVisibility(songs: songs)
                owner.updateDisplayItems()
                owner.bannerContainerView.setEnabled(!songs.isEmpty, rootViewController: owner)
            }
            .disposed(by: disposeBag)
        reactor.state.map { state -> String? in
            if let errorDescription = state.errorDescription {
                return errorDescription
            }
            return state.hasCompletedSearch && state.isEmpty ? String(localized: "search.empty") : nil
        }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind { owner, message in
                owner.warningText.text = message
                owner.warningText.isHidden = message == nil
                if let message {
                    UIAccessibility.post(notification: .announcement, argument: message)
                }
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
        navigationItem.title = String(localized: "search.title")
        navigationItem.largeTitleDisplayMode = .never
    }

    private func updateFilterMenu() {
        let scopeActions = SearchScopeType.allCases.map { scope in
            UIAction(
                title: scope.localizedTitle,
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
            UIMenu(title: String(localized: "search.criteria"), options: .displayInline, children: scopeActions),
            UIMenu(title: String(localized: "search.service"), options: .displayInline, children: brandActions)
        ])
        filterButton.setTitle(
            "\(selectedSearchScope.localizedTitle) · \(selectedBrand.name)  ",
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
        let action = UIAlertAction(title: String(localized: "action.ok"), style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true)
    }

    @objc private func searchTextFieldDidSubmit() {
        view.endEditing(true)
        reactor?.action.onNext(.search(searchBar.text))
    }

    private func updateNativeAdVisibility(songs: [Song]) {
        nativeAdPlacement.setEnabled(
            !songs.isEmpty,
            maximumAdCount: songs.nativeAdSlotCount
        )
    }

    private func updateDisplayItems() {
        displayItems.accept(
            songs.displayItems(nativeAdCount: nativeAdPlacement.availableAdCount)
        )
    }

    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let requestedAdCount = indexPaths.compactMap { indexPath -> Int? in
            let items = displayItems.value
            guard items.indices.contains(indexPath.row), case let .song(_, rank) = items[indexPath.row] else {
                return nil
            }
            return songs.nativeAdCountToRequest(prefetchingSongAt: rank)
        }.max()
        if let requestedAdCount {
            nativeAdPlacement.requestAds(upTo: requestedAdCount)
        }
    }
}
