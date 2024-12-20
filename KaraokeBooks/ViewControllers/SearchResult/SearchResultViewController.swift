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
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController()
        return searchController
    }()
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
    }
    
    func bind(reactor: SearchResultReactor) {
        searchResultTableView.rx.itemSelected
            .map{Reactor.Action.songDetail($0)}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        searchResultTableView.rx.prefetchRows
            .flatMap{Observable.from($0)}
            .map{ Reactor.Action.currentRow($0)}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        brandSegmentedControl.rx.selectedSegmentIndex
            .flatMap{ index in
                let type = BrandType.allCases[index]
                let first = Observable.just(Reactor.Action.brandType(type))
                let second = Observable.just(Reactor.Action.search)
                return Observable.concat([first, second])
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        searchController.searchBar.rx.selectedScopeButtonIndex
            .flatMap{ index in
                let type = SearchScopeType.allCases[index]
                let first = Observable.just(Reactor.Action.searchType(type))
                let second = Observable.just(Reactor.Action.search)
                return Observable.concat([first, second])
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        searchController.searchBar.rx.value
            .distinctUntilChanged()
            .debounce(RxTimeInterval.microseconds(5), scheduler: MainScheduler.instance)
            .map{
                let query = $0 == "" ? nil : $0
                return Reactor.Action.searchQuery(query)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        searchController.searchBar.rx.textDidEndEditing
            .map{Reactor.Action.search}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        
        reactor.state.map{$0.songs}
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: searchResultTableView.rx.items(cellIdentifier: SongTableViewCell.identifier, cellType: SongTableViewCell.self)) { index, item, cell in
                cell.setup(rank: index, song: item)
            }
            .disposed(by: disposeBag)
        reactor.state.map{$0.isEmpty}
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: warningText.rx.isHidden)
            .disposed(by: disposeBag)
        reactor.state.compactMap{$0.errorDescription}
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind { owner, msg in
                owner.showAlert(header: "Error", body: msg)
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
    }
}

extension SearchResultViewController {
    func setupViews() {
        view.backgroundColor = .customBackground
        
        [searchResultTableView, brandSegmentedControl, warningText].forEach {
            view.addSubview($0)
        }
        brandSegmentedControl.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(16.0)
            $0.left.right.equalToSuperview().inset(16.0)
        }
        searchResultTableView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(brandSegmentedControl.snp.bottom)
        }
        warningText.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    func setupNavigationBar() {
        navigationItem.title = SearchScopeType.title.name
        navigationItem.searchController = searchController
        searchController.searchBar.placeholder = SearchScopeType.title.name
        searchController.searchBar.scopeButtonTitles = [
            SearchScopeType.title.name,
            SearchScopeType.singer.name
        ]
        searchController.searchBar.showsScopeBar = true
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    private func showAlert(header: String, body: String) {
        let alert = UIAlertController(title: header, message: body, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true)
    }
}
