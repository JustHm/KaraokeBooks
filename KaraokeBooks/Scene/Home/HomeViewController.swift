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
        collectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: CollectionViewCell.identifier)
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(SongTableViewCell.self, forCellReuseIdentifier: SongTableViewCell.identifier)
        tableView.register(RankTableViewHeader.self, forHeaderFooterViewReuseIdentifier: RankTableViewHeader.identifier)
        tableView.dataSource = presenter
        tableView.delegate = presenter
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionHeaderTopPadding = 0
        tableView.layer.cornerRadius = 15.0
        tableView.clipsToBounds = true
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewDidLoad()
    }
}

extension HomeViewController: HomeProtocol {
    func moveToDetailViewController(song: Song) {
        let viewController = SongDetailViewController()
        viewController.setup(song: song)
//        viewController.modalPresentationStyle = 
        present(viewController, animated: true)
    }
    
    func reloadTableView() {
        tableView.reloadData()
    }
    
    func setupViews() {
        [homeItemCollectionView, brandSegmentedControl,  tableView].forEach {
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
        
        tableView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16.0)
            $0.top.equalTo(brandSegmentedControl.snp.bottom)
            $0.bottom.equalToSuperview()
        }
    }
    
    func setupNavigationBar() {
        navigationItem.title = "노래방 책"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "titleIcon"), style: .plain, target: nil, action: nil)
        let searchCon = UISearchController()
        navigationItem.searchController = searchCon
        searchCon.searchBar.placeholder = "노래,가수,번호로 검색"
    }
}

private extension HomeViewController {
    @objc func valueChangedBrandSegmentedControl(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        let brand = BrandType.allCases[selectedIndex]
        presenter.rankRequest(brand: brand)
    }
}
