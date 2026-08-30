//
//  SearchResultViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/16.
//

import UIKit
import SnapKit
import ReactorKit

final class SearchResultViewController: UIViewController, View {
    typealias Reactor = SearchResultReactor
    var disposeBag = DisposeBag()

    private var selectedSearchScope = SearchScopeType.title
    private var selectedBrand = BrandType.tj

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
        label.sizeToFit()
        label.textColor = .customPrimaryText
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
        searchBar.searchTextField.addTarget(
            self,
            action: #selector(searchTextFieldDidSubmit),
            for: .editingDidEndOnExit
        )
        updateFilterMenu()
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
            .bind(to: searchResultTableView.rx.items(cellIdentifier: SongTableViewCell.identifier, cellType: SongTableViewCell.self)) { index, item, cell in
                cell.setup(rank: index, song: item)
            }
            .disposed(by: disposeBag)
        reactor.state.map { state in
            !(state.hasCompletedSearch && state.isEmpty)
        }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: warningText.rx.isHidden)
            .disposed(by: disposeBag)
        reactor.state.compactMap{$0.errorDescription}
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind { owner, msg in
                owner.showAlert(header: "검색 실패", body: msg)
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
        
        [searchBar, filterTitleLabel, filterButton, searchResultTableView, warningText, loadIndicator].forEach {
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
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(filterButton.snp.bottom).offset(8.0)
        }
        warningText.snp.makeConstraints {
            $0.center.equalToSuperview()
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
        reactor?.action.onNext(.search(searchBar.text))
    }
}
