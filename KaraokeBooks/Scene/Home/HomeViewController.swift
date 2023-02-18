//
//  HomeViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import UIKit
import SnapKit

class HomeViewController: UIViewController {
    private lazy var presenter = HomePresenter(viewController: self)
    private lazy var loadIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.isHidden = true
        return indicator
    }()
    private lazy var brandSegmentedControl: ClearSegmentedControl = {
        let segmentedControl = ClearSegmentedControl()
        BrandType.allCases.enumerated().forEach { (index, value) in
            segmentedControl.insertSegment(
                withTitle: value.replace,
                at: index,
                animated: false)
        }
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(
            self,
            action: #selector(valueChangedBrandSegmentedControl),
            for: .valueChanged
        )
        return segmentedControl
    }()
    private lazy var homeItemCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = presenter
        collectionView.delegate = presenter
        collectionView.register(HomeItemCollectionViewCell.self, forCellWithReuseIdentifier: HomeItemCollectionViewCell.identifier)
        collectionView.backgroundColor = .customBackground
        return collectionView
    }()
    private lazy var rankTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(SongTableViewCell.self, forCellReuseIdentifier: SongTableViewCell.identifier)
        tableView.register(RankTableViewHeader.self, forHeaderFooterViewReuseIdentifier: RankTableViewHeader.identifier)
        tableView.dataSource = presenter
        tableView.delegate = presenter
        tableView.showsVerticalScrollIndicator = false
        if #available(iOS 15.0, *) { //ios15 부터 header padding 적용되어서 간격 넓어짐 제거
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.layer.cornerRadius = 15.0
        tableView.clipsToBounds = true
        tableView.backgroundColor = .customForeground2
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewDidLoad()
    }
}

extension HomeViewController: HomeProtocol {
    func activeIndicator(isStart: Bool) {
        loadIndicator.isHidden = !isStart
        if isStart {
            loadIndicator.startAnimating()
        } else {
            loadIndicator.stopAnimating()
        }
    }
    
    func reloadTableView() {
        rankTableView.reloadData()
    }
    
    func setupViews() {
        [homeItemCollectionView, brandSegmentedControl, rankTableView, loadIndicator].forEach {
            view.addSubview($0)
        }
        
        homeItemCollectionView.snp.makeConstraints {
            $0.left.right.equalToSuperview()//.inset(16.0)
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(8.0)
            $0.height.equalTo(120)
        }
        
        brandSegmentedControl.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(32.0)
            $0.top.equalTo(homeItemCollectionView.snp.bottom)
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
        navigationItem.title = "노래방 책"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "music.note.house"),
            style: .plain,
            target: nil,
            action: nil
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(didTapRightSearchButton)
        )
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

private extension HomeViewController {
    @objc func valueChangedBrandSegmentedControl(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        let brand = BrandType.allCases[selectedIndex]
        presenter.rankRequest(brand: brand)
    }
    @objc func didTapRightSearchButton() {
        presenter.didTapRightSearchButton()
    }
}
