//
//  HomePresenter.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//
import UIKit

protocol HomeProtocol: AnyObject {
    func setupViews()
    func setupNavigationBar()
    func reloadTableView()
}

final class HomePresenter: NSObject {
    private weak var viewController: HomeProtocol?
    private let searchManager: KaraokeSearchManagerProtocol!
    
    private var songs: [Song] = []
    private var brandSelected: BrandType = BrandType.allCases[0]
    private var dateSelected: RankDateType = RankDateType.allCases[0]
    
    init(
        viewController: HomeProtocol,
        searchManager: KaraokeSearchManagerProtocol = KaraokeSearchManager()
    ) {
        self.viewController = viewController
        self.searchManager = searchManager
    }
    func viewDidLoad() {
        viewController?.setupViews()
        viewController?.setupNavigationBar()
        rankRequest(brand: BrandType.allCases[0])
    }
    func searchRequest(brand: BrandType, query: String, searchType: SearchType) {
        searchManager.searchRequest(
            brand: brand,
            query: query,
            searchType: searchType
        ) { [weak self] songs in
            self?.songs = songs
        }
    }
    func rankRequest(brand: BrandType) {
        brandSelected = brand
        searchManager.rankRequest(
            brand: brandSelected,
            date: dateSelected
        ) { [weak self] songs in
            self?.songs = songs
            self?.viewController?.reloadTableView()
        }
    }
}

extension HomePresenter: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        songs.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SongTableViewCell.identifier,
            for: indexPath
        ) as? SongTableViewCell
        let song = songs[indexPath.row]
        cell?.setup(rank: indexPath.row, song: song)
        return cell ?? UITableViewCell()
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView
            .dequeueReusableHeaderFooterView(
                withIdentifier: RankTableViewHeader.identifier
            ) as? RankTableViewHeader
        header?.setup(delegate: self)
        return header
    }
}
extension HomePresenter: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        50.0
    }
}

extension HomePresenter: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        HomeList.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionViewCell.identifier, for: indexPath) as? CollectionViewCell
        let title = HomeList.allCases[indexPath.row].rawValue
        cell?.setup(title: title)
        return cell ?? UICollectionViewCell()
    }
    
    
}

extension HomePresenter: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 100.0, height: 100.0)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        .init(top: 8.0, left: 16.0, bottom: 0.0, right: 16.0)
    }
}

extension HomePresenter: NewsListTableViewHeaderDelegate {
    func didSelectTag(_ selectedBrand: RankDateType) {
        dateSelected = selectedBrand
        self.rankRequest(brand: brandSelected)
    }
    
}
