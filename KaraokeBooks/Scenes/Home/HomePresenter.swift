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
    func activeIndicator(isStart: Bool)
    func moveToDetailViewController(song: Song)
    func moveToFavoriteViewController()
    func moveToRecentSongViewController()
    func moveToSearchResultViewController()
}

final class HomePresenter: NSObject {
    private weak var viewController: HomeProtocol?
    private let searchManager: KaraokeSearchManagerProtocol!
    private var songs: [Song] = []
    private var currentBrand: BrandType = BrandType.allCases[0]
    private var currentDate: RankDateType = RankDateType.allCases[0]
    
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
    func rankRequest(brand: BrandType) {
        currentBrand = brand
        viewController?.activeIndicator(isStart: true)
        Task { [weak self] in
            do {
                let songs = try await searchManager.rankRequest(brand: currentBrand, date: currentDate)
                self?.songs = songs ?? []
                await MainActor.run { [weak self] in
                    self?.viewController?.reloadTableView()
                    self?.viewController?.activeIndicator(isStart: false)
                }
            }
            catch {
                print("Home-ERROR: \(error.localizedDescription)")
            }
        }
    }
    func didTapRightSearchButton() {
        viewController?.moveToSearchResultViewController()
    }
}
// MARK: RankTableView DataSource
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
// MARK: RankTableView Delegate
extension HomePresenter: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        50.0
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let song = songs[indexPath.row]
        viewController?.moveToDetailViewController(song: song)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
// MARK: HomeItemCollectionView DataSource
extension HomePresenter: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        HomeList.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeItemCollectionViewCell.identifier, for: indexPath) as? HomeItemCollectionViewCell
        let title = HomeList.allCases[indexPath.row].rawValue
        cell?.setup(title: title)
        return cell ?? UICollectionViewCell()
    }
}
// MARK: HomeItemCollectionView Delegate
extension HomePresenter: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let mainWidth = collectionView.frame.width
        let mainHeight = collectionView.frame.height
        let width: CGFloat = (mainWidth / 2.0) - 32.0
        let height: CGFloat = mainHeight - 16.0
        return CGSize(width: width, height: height)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        .init(top: 8.0, left: 16.0, bottom: 0.0, right: 16.0)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch HomeList.allCases[indexPath.row] {
        case .favourite:
            viewController?.moveToFavoriteViewController()
        case .newSong:
            viewController?.moveToRecentSongViewController()
            break
        }
    }
}
// MARK: RankDateTableViewHeaderDelegate
extension HomePresenter: RankDateTableViewHeaderDelegate {
    func didSelectTag(_ selectedBrand: RankDateType) {
        currentDate = selectedBrand
        self.rankRequest(brand: currentBrand)
    }
}
