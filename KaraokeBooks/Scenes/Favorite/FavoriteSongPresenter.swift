//
//  FavoriteSongPresenter.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/12.
//

import UIKit

protocol FavoriteSongProtocol: AnyObject {
    func setupViews()
    func reloadTableView()
    func isEmptyTableView(isEmpty: Bool)
    func moveToDetailViewController(song: Song)
}

final class FavoriteSongPresenter: NSObject {
    private weak var viewController: FavoriteSongProtocol?
    private let userDefaults: UserDefaultsManagerProtocol!
    private var favoriteSongs: [Song]
    private var currentBrand: BrandType = BrandType.allCases[0]
    init(
        viewController: FavoriteSongProtocol,
        userDefaults: UserDefaultsManagerProtocol = UserDefaultsManager()
    ) {
        self.viewController = viewController
        self.userDefaults = userDefaults
        favoriteSongs = userDefaults.getFavoriteSong(brand: currentBrand)
    }
    func viewDidLoad() {
        viewController?.setupViews()
        viewController?.isEmptyTableView(isEmpty: !favoriteSongs.isEmpty)
    }
    func valueChangedBrandSegmentedControl(brand: BrandType) {
        favoriteSongs = userDefaults.getFavoriteSong(brand: brand)
        viewController?.isEmptyTableView(isEmpty: !favoriteSongs.isEmpty)
        viewController?.reloadTableView()
    }
    func reload() {
        favoriteSongs = userDefaults.getFavoriteSong(brand: currentBrand)
        viewController?.reloadTableView()
    }
}
// MARK: FavoriteSongTableView DataSource
extension FavoriteSongPresenter: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        favoriteSongs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SongTableViewCell.identifier,
            for: indexPath) as? SongTableViewCell
        let song = favoriteSongs[indexPath.row]
        cell?.setup(rank: 0, song: song)
        return cell ?? UITableViewCell()
    }
}
// MARK: FavoriteSongTableView Delegate
extension FavoriteSongPresenter: UITableViewDelegate {
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            let song = favoriteSongs[indexPath.row]
            favoriteSongs.remove(at: indexPath.row)
            userDefaults.deleteFavoriteSong(song)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            viewController?.isEmptyTableView(isEmpty: !favoriteSongs.isEmpty)
        default:
            break
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let song = favoriteSongs[indexPath.row]
        viewController?.moveToDetailViewController(song: song)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
