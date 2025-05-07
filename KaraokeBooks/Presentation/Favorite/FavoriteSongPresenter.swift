////
////  FavoriteSongPresenter.swift
////  KaraokeBooks
////
////  Created by 안정흠 on 2023/02/12.
////
//
//import UIKit
//
//protocol FavoriteSongProtocol: AnyObject {
//    func setupViews()
//    func reloadTableView()
//    func isEmptyTableView(isEmpty: Bool)
//    func moveToDetailViewController(song: Song)
//}
//
//final class FavoriteSongPresenter: NSObject {
//    private weak var viewController: FavoriteSongProtocol?
//    private var favoriteSongs: [Song] = []
//    private var currentBrand: BrandType = BrandType.allCases[0]
//    
//    init(viewController: FavoriteSongProtocol) {
//        self.viewController = viewController
//    }
//    func viewDidLoad() {
//        viewController?.setupViews()
//        reload()
//    }
//    func valueChangedBrandSegmentedControl(brand: BrandType) {
//        currentBrand = brand
//        reload()
//    }
//    func reload() {
//        favoriteSongs = PersistenceManager.shared.fetchByBrand(brand: currentBrand.name).map({
//            return Song(brand: currentBrand,
//                        no: $0.number!,
//                        title: $0.title!,
//                        singer: $0.singer!,
//                        composer: $0.composer!,
//                        lyricist: $0.lyricist!,
//                        release: "",
//                        isStar: true)
//        })
//        viewController?.isEmptyTableView(isEmpty: !favoriteSongs.isEmpty)
//        viewController?.reloadTableView()
//    }
//}
//// MARK: FavoriteSongTableView DataSource
//extension FavoriteSongPresenter: UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        favoriteSongs.count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(
//            withIdentifier: SongTableViewCell.identifier,
//            for: indexPath) as? SongTableViewCell
//        let song = favoriteSongs[indexPath.row]
//        cell?.setup(rank: 0, song: song)
//        return cell ?? UITableViewCell()
//    }
//}
//// MARK: FavoriteSongTableView Delegate
//extension FavoriteSongPresenter: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        switch editingStyle {
//        case .delete:
//            let song = favoriteSongs[indexPath.row]
//            favoriteSongs.remove(at: indexPath.row)
//            PersistenceManager.shared.deleteSong(id: song.id)
//            tableView.deleteRows(at: [indexPath], with: .automatic)
//            viewController?.isEmptyTableView(isEmpty: !favoriteSongs.isEmpty)
//        default:
//            break
//        }
//    }
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let song = favoriteSongs[indexPath.row]
//        viewController?.moveToDetailViewController(song: song)
//        tableView.deselectRow(at: indexPath, animated: true)
//    }
//}
