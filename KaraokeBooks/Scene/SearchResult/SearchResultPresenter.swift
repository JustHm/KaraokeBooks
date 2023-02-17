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
        didTapSearchFilterButton(title: "노래 검색")
    }
    func valueChangedBrandSegmentedControl(brand: BrandType) {
        currentBrand = brand
        searchSongs()
    }
    func didTapSearchFilterButton(title: String) {
        viewController?.setupNavigationTitle(title: title)
        switch title {
        case "노래 검색":
            currentSearchType = .song
        case "가수 검색":
            currentSearchType = .singer
        default:
            currentSearchType = .song
        }
    }
    private func searchSongs() {
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

extension SearchResultPresenter: UISearchBarDelegate {
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        query = text
        searchSongs()
    }
}

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

extension SearchResultPresenter: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let song = result[indexPath.row]
        viewController?.moveToDetailViewController(song: song)
        tableView.cellForRow(at: indexPath)?.isSelected = false
    }
}
