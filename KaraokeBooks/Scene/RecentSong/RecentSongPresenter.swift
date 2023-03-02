//
//  RecentSongPresenter.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/12.
//

import UIKit

protocol RecentSongProtocol: AnyObject {
    func setupViews()
    func reloadTableView()
    func moveToDetailViewController(song: Song)
}

final class RecentSongPresenter: NSObject {
    private weak var viewController: RecentSongProtocol?
    private let searchManager: KaraokeSearchManagerProtocol!

    private var currentDate: String = "202302"
    private var currentBrand: BrandType = BrandType.allCases[0]
    private var tjRecentSongs: [Song] = []
    private var kyRecentSongs: [Song] = []
    init(
        viewController: RecentSongProtocol,
        searchManager: KaraokeSearchManagerProtocol = KaraokeSearchManager()
    ) {
        self.viewController = viewController
        self.searchManager = searchManager
    }
    
    func viewDidLoad() {
        viewController?.setupViews()
        dateChanged(date: Date())
        searchRecentSongsAllBrand()
    }
    func valueChangedBrandSegmentedControl(brand: BrandType) {
        currentBrand = brand
        viewController?.reloadTableView()
    }
    func dateChanged(date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMM"
        currentDate = formatter.string(from: date)
        searchRecentSongsAllBrand()
    }
    func searchRecentSongsAllBrand() {
        searchRecentSongs(brand: .tj)
        searchRecentSongs(brand: .kumyoung)
    }
    private func searchRecentSongs(brand: BrandType) {
        Task { [weak self] in
            do {
                let songs = try await self?.searchManager.searchReqeust(brand: brand, query: currentDate, searchType: .release)
                guard let songs else { return }
                //노래별 저장
                switch brand {
                case .tj:
                    self?.tjRecentSongs = songs
                case .kumyoung:
                    self?.kyRecentSongs = songs
                }
                
                await MainActor.run { [weak self] in
                    self?.viewController?.reloadTableView()
                }
            }
            catch {
                print("RecentSong-ERROR: \(error.localizedDescription)")
            }
        }
    }
}
// MARK: RecentSongTableView DataSource
extension RecentSongPresenter: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch currentBrand {
        case .tj:
            return tjRecentSongs.count
        case .kumyoung:
            return kyRecentSongs.count
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SongTableViewCell.identifier,
            for: indexPath) as? SongTableViewCell
        var song: Song
        switch currentBrand {
        case .tj:
            song = tjRecentSongs[indexPath.row]
        case .kumyoung:
            song = kyRecentSongs[indexPath.row]
        }
        cell?.setup(rank: 0, song: song)
        return cell ?? UITableViewCell()
    }
}
// MARK: RecentSongTableView Delegate
extension RecentSongPresenter: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var song: Song
        switch currentBrand {
        case .tj:
            song = tjRecentSongs[indexPath.row]
        case .kumyoung:
            song = kyRecentSongs[indexPath.row]
        }
        viewController?.moveToDetailViewController(song: song)
        tableView.cellForRow(at: indexPath)?.isSelected = false
    }
}
