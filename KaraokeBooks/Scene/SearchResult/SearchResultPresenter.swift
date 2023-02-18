//
//  SearchResultPresenter.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/16.
//

import UIKit

protocol SearchResultProtocol {
    func setupViews()
    func setupNavigationBar()
    func setupNavigationTitle(title: String)
    func reloadTableView()
    func moveToDetailViewController(song: Song)
    func isEmptyTableView(isEmpty: Bool)
}

final class SearchResultPresenter: NSObject {
    private weak var viewController: SearchResultViewController?
    private let searchManager: KaraokeSearchManagerProtocol!
    private var currentBrand: BrandType = BrandType.allCases[0]
    private var currentSearchType: SearchType = .song
    private var query: String = ""
    private var result: [Song] = []
    init(
        viewController: SearchResultViewController,
        searchManager: KaraokeSearchManagerProtocol = KaraokeSearchManager()) {
            self.viewController = viewController
            self.searchManager = searchManager
        }
    
    func viewDidLoad() {
        viewController?.setupViews()
        viewController?.setupNavigationBar()
    }
    func valueChangedBrandSegmentedControl(brand: BrandType) {
        currentBrand = brand
        searchSongs()
    }
    private func searchSongs() {
        guard query != "" else { return }
        searchManager.searchRequest(
            brand: currentBrand,
            query: query,
            searchType: currentSearchType
        ) {[weak self] songs in
            self?.result = songs
            self?.viewController?.isEmptyTableView(isEmpty: !songs.isEmpty)
            self?.viewController?.reloadTableView()
        }
    }
}
// MARK: SearchBar Delegate
extension SearchResultPresenter: UISearchBarDelegate {
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        query = text
        searchSongs()
    }
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        guard let title = searchBar.scopeButtonTitles?[selectedScope] else { return }
        switch title {
        case "노래 검색":
            currentSearchType = .song
        case "가수 검색":
            currentSearchType = .singer
        default:
            currentSearchType = .song
        }
        viewController?.setupNavigationTitle(title: title)
        searchSongs()
    }
}
// MARK: SearchResultTableView DataSource
extension SearchResultPresenter: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        result.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SongTableViewCell.identifier,
            for: indexPath
        ) as? SongTableViewCell
        let song = result[indexPath.row]
        cell?.setup(rank: indexPath.row, song: song)
        return cell ?? UITableViewCell()
    }
}
// MARK: SearchResultTableView Delegate
extension SearchResultPresenter: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let song = result[indexPath.row]
        viewController?.moveToDetailViewController(song: song)
        tableView.cellForRow(at: indexPath)?.isSelected = false
    }
}
