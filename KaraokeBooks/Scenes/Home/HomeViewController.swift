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
    
    private lazy var stackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.distribution = .fillEqually
        return stack
    }()
    
    private lazy var favoriteListButton: MoveSceneButton = {
        let button = MoveSceneButton(title: "애창곡", symbol: "star")
        return button
    }()
    
    private lazy var searchButton: MoveSceneButton = {
        let button = MoveSceneButton(title: "노래검색", symbol: "magnifyingglass")
        return button
    }()
    
    private lazy var rankTableHeader = RankTableViewHeader()
    
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
        tableView.register(SongTableViewCell.self,
                           forCellReuseIdentifier: SongTableViewCell.identifier)
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
        [favoriteListButton, searchButton].forEach { stackView.addArrangedSubview($0) }
        [stackView, rankTableHeader, brandSegmentedControl, rankTableView, loadIndicator].forEach {
            view.addSubview($0)
        }
        
        stackView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16.0)
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(16.0)
            $0.height.equalTo(120)
        }
        
        rankTableHeader.snp.makeConstraints {
            $0.top.equalTo(stackView.snp.bottom).offset(16.0)
            $0.left.right.equalToSuperview().inset(32.0)
        }
        
        brandSegmentedControl.snp.makeConstraints {
            $0.top.equalTo(rankTableHeader.snp.bottom)
            $0.left.right.equalToSuperview().inset(32.0)
        }
        
        rankTableView.snp.makeConstraints {
            $0.top.equalTo(brandSegmentedControl.snp.bottom).offset(2.0)
            $0.left.right.equalToSuperview().inset(16.0)
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
        rankTableHeader.currentTitle
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
        //State
        reactor.state.map{$0.isLoading}
            .distinctUntilChanged()
            .bind(onNext: { [weak self] in
                self?.loadIndicator.isHidden = !$0
                $0 ? self?.loadIndicator.startAnimating() : self?.loadIndicator.stopAnimating()
            })
            .disposed(by: disposeBag)
        reactor.state.observe(on: MainScheduler.instance)
            .map{ $0.popularList }
            .bind(to: rankTableView.rx.items(cellIdentifier: SongTableViewCell.identifier, cellType: SongTableViewCell.self)) { index, item, cell in
                cell.setup(rank: index, song: item)
            }
            .disposed(by: disposeBag)
    }
}
