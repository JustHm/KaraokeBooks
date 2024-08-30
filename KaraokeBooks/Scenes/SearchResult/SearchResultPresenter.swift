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
    private var currentSearchType: SearchType = .title
    private var query: String = ""
    private var result: [Song] = []
    private var currentPage: Int = 1
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
        currentPage = 1
        result = []
        currentBrand = brand
        searchSongs(brand: brand)
    }
    private func searchSongs(brand: BrandType) {
        guard query != "" else { return }
        Task { [weak self] in
            do {
                let songs = try await self?.searchManager.searchReqeust(brand: currentBrand,
                                                                        query: query,
                                                                        searchType: currentSearchType,
                                                                        page: currentPage)
                self?.result += songs ?? []
                self?.currentPage += 1
                await MainActor.run { [weak self] in
                    self?.viewController?.isEmptyTableView(isEmpty: !(songs?.isEmpty ?? false))
                    self?.viewController?.reloadTableView()
                }
            }
            catch {
                print("SearchResult-ERROR: \(error.localizedDescription)")
            }
        }
    }
}
// MARK: SearchBar Delegate
extension SearchResultPresenter: UISearchBarDelegate {
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        query = text.replacingOccurrences(of: " ", with: "")
        result = []
        currentPage = 1
        searchSongs(brand: currentBrand)
    }
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        guard let title = searchBar.scopeButtonTitles?[selectedScope] else { return }
        switch title {
        case "노래 검색":
            currentSearchType = .title
        case "가수 검색":
            currentSearchType = .singer
        default:
            currentSearchType = .title
        }
        viewController?.setupNavigationTitle(title: title)
        result = []
        currentPage = 1
        searchSongs(brand: currentBrand)
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
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
// MARK: SearchResultTableView DataSourcePrefetching
extension SearchResultPresenter: UITableViewDataSourcePrefetching {
    // 곧 보여질 셀들을 미리 불러오는 역할
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        guard currentPage != 1 else { return }
        
        indexPaths.forEach { // 1 page당 25 item
            if (($0.row + 1) / 20 + 1) == currentPage {
                self.searchSongs(brand: currentBrand)
            }
        }
    }
}
