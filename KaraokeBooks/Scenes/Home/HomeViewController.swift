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
    
    var disposeBag = DisposeBag()
    
    private var stackView = UIStackView()
    private var moveToSearchButton: UIButton = {
        let button = UIButton()
        return button
    }()
    private var moveToBookmarkButton: UIButton = {
        let button = UIButton()
        return button
    }()
    
    private lazy var loadIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .customPrimaryText
        indicator.isHidden = true
        indicator.startAnimating()
        return indicator
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
    private lazy var rankTableView: SongTableView = {
        let tableView = SongTableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.register(SongTableViewCell.self,
                           forCellReuseIdentifier: SongTableViewCell.identifier)
        tableView.register(RankTableViewHeader.self,
                           forHeaderFooterViewReuseIdentifier: RankTableViewHeader.identifier)
        return tableView
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
        setupNavigationBar()
    }
}

extension HomeViewController {
    func setupViews() {
        [brandSegmentedControl, rankTableView, loadIndicator].forEach {
            view.addSubview($0)
        }
        
//        homeItemCollectionView.snp.makeConstraints {
//            $0.left.right.equalToSuperview()
//            $0.top.equalTo(view.safeAreaLayoutGuide).inset(8.0)
//            $0.height.equalTo(120)
//        }
        
        brandSegmentedControl.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(32.0)
//            $0.top.equalTo(homeItemCollectionView.snp.bottom)
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(8.0)
        }
        
        rankTableView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16.0)
            $0.top.equalTo(brandSegmentedControl.snp.bottom)
            $0.bottom.equalToSuperview()
        }
        loadIndicator.snp.makeConstraints {
            $0.center.equalTo(rankTableView)
        }
    }
    
    func setupNavigationBar() {
        navigationItem.title = "노래방Book"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    func moveToDetailViewController(song: Song) {
        let viewController = SongDetailViewController(song: song)
        present(viewController, animated: true)
    }
    func moveToFavoriteViewController() {
        let viewController = FavoriteSongViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
    func moveToRecentSongViewController() {
        let viewController = RecentSongViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
    func moveToRandomSongViewController() {
        let viewController = FavoriteSongViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
    func moveToSearchResultViewController() {
        let viewController = SearchResultViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension HomeViewController {
    func bind(reactor: HomeReactor) {
        //Action
        brandSegmentedControl.rx.selectedSegmentIndex
            .map{Reactor.Action.brandType(BrandType.allCases[$0])}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        rankTableView.rx.itemSelected
            .map{Reactor.Action.songDetail($0)}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        (rankTableView.headerView(forSection: 0) as? RankTableViewHeader)?
            .dateSegmentedControl.rx.selectedSegmentIndex
            .map{Reactor.Action.rankDateType(RankDateType.allCases[$0])}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        //State
        reactor.state.map{$0.isLoading}
            .distinctUntilChanged()
            .bind(onNext: { [weak self] in
                self?.loadIndicator.isHidden = !$0
                $0 ? self?.loadIndicator.startAnimating() : self?.loadIndicator.stopAnimating()
            })
            .disposed(by: disposeBag)
        reactor.state.map{$0.popularList}
            .observe(on: MainScheduler.instance)
            .bind(to: rankTableView.rx.items(cellIdentifier: SongTableViewCell.identifier, cellType: SongTableViewCell.self)) { index, item, cell in
                cell.setup(rank: index, song: item)
            }
            .disposed(by: disposeBag)
    }
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView
            .dequeueReusableHeaderFooterView(
                withIdentifier: RankTableViewHeader.identifier
            ) as? RankTableViewHeader
        header?.setup()
        return header
    }
}
