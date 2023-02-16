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
    init(
        viewController: FavoriteSongProtocol,
        userDefaults: UserDefaultsManagerProtocol = UserDefaultsManager()
    ) {
        self.viewController = viewController
        self.userDefaults = userDefaults
        favoriteSongs = userDefaults.getFavoriteSong()
    }
    func viewDidLoad() {
        favoriteSongs = userDefaults.getFavoriteSong()
        viewController?.setupViews()
        viewController?.isEmptyTableView(isEmpty: !favoriteSongs.isEmpty)
    }
    func didTapEditButton() {
        
    }
}

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
        tableView.cellForRow(at: indexPath)?.isSelected = false
    }
}
