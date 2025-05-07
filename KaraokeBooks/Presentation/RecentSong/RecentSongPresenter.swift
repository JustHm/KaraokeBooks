////
////  RecentSongPresenter.swift
////  KaraokeBooks
////
////  Created by 안정흠 on 2023/02/12.
////
//
//import UIKit
//
//protocol RecentSongProtocol: AnyObject {
//    func setupViews()
//    func reloadTableView()
//    func moveToDetailViewController(song: Song)
//}
//
//final class RecentSongPresenter: NSObject {
//    private weak var viewController: RecentSongProtocol?
//    private let searchManager: KaraokeSearchManagerProtocol!
//    
//    private var currentDate: String = "202302"
//    private var currentBrand: BrandType = BrandType.allCases[0]
//    private var tjRecentSongs: [Song] = []
//    private var kyRecentSongs: [Song] = []
//    private var currentPage: Int = 1
//    
//    init(
//        viewController: RecentSongProtocol,
//        searchManager: KaraokeSearchManagerProtocol = KaraokeSearchManager()
//    ) {
//        self.viewController = viewController
//        self.searchManager = searchManager
//    }
//    
//    func viewDidLoad() {
//        viewController?.setupViews()
//        dateChanged(date: Date())
//    }
//    func valueChangedBrandSegmentedControl(brand: BrandType) {
//        currentBrand = brand
//        viewController?.reloadTableView()
//    }
//    func dateChanged(date: Date) {
//        currentDate = date.dateToString(format: "yyyyMM")
//        searchRecentSongs()
//    }
//    
//    private func searchRecentSongs() {
//        Task { [weak self] in
//            do {
//                async let tj = searchManager.recentRequest(brand: .tj,
//                                                           query: currentDate,
//                                                           searchType: .release,
//                                                           page: currentPage)
//                async let ky = searchManager.recentRequest(brand: .kumyoung,
//                                                           query: currentDate,
//                                                           searchType: .release,
//                                                           page: currentPage)
//                let songs = try await [tj, ky]
//                self?.tjRecentSongs = songs[0]
//                self?.kyRecentSongs = songs[1]
//                self?.currentPage += 1
//                await MainActor.run { [weak self] in
//                    self?.viewController?.reloadTableView()
//                }
//            }
//            catch {
//                print("RecentSong-ERROR: \(error.localizedDescription)")
//            }
//        }
//    }
//}
//// MARK: RecentSongTableView DataSource
//extension RecentSongPresenter: UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        switch currentBrand {
//        case .tj:
//            return tjRecentSongs.count
//        case .kumyoung:
//            return kyRecentSongs.count
//        }
//    }
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(
//            withIdentifier: SongTableViewCell.identifier,
//            for: indexPath) as? SongTableViewCell
//        var song: Song
//        switch currentBrand {
//        case .tj:
//            song = tjRecentSongs[indexPath.row]
//        case .kumyoung:
//            song = kyRecentSongs[indexPath.row]
//        }
//        cell?.setup(rank: 0, song: song)
//        return cell ?? UITableViewCell()
//    }
//}
//// MARK: RecentSongTableView Delegate
//extension RecentSongPresenter: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        var song: Song
//        switch currentBrand {
//        case .tj:
//            song = tjRecentSongs[indexPath.row]
//        case .kumyoung:
//            song = kyRecentSongs[indexPath.row]
//        }
//        viewController?.moveToDetailViewController(song: song)
//        tableView.deselectRow(at: indexPath, animated: true)
//    }
//}
//// MARK: RecentSongTableView DataSourcePrefetching
//extension RecentSongPresenter: UITableViewDataSourcePrefetching {
//    // 곧 보여질 셀들을 미리 불러오는 역할
//    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
//        guard currentPage != 1 else { return }
//        
//        indexPaths.forEach { // 1 page당 25 item
//            if (($0.row + 1) / 20 + 1) == currentPage {
//                self.searchRecentSongs()
//            }
//        }
//    }
//}
