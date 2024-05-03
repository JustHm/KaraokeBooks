//
//  SongDetailPresenter.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/10.
//

import Foundation

protocol SongDetailProtocol: AnyObject {
    func setupViews()
    func setupLinkURL(song: Song)
    func setupStarButton(isStar: Bool)
    func setupViewHeight()
    func moveToYoutube()
    func dismiss()
}

final class SongDetailPresenter {
    private weak var viewController: SongDetailProtocol?
    private var currentSong: Song
    init(viewController: SongDetailProtocol, song: Song) {
        self.viewController = viewController
        self.currentSong = song
    }
    func viewDidLoad() {
        viewController?.setupViews()
        viewController?.setupViewHeight()
        viewController?.setupLinkURL(song: currentSong)
        currentSong.isStar = PersistenceManager.shared.isExist(songID: currentSong.id)
        viewController?.setupStarButton(isStar: currentSong.isStar)
    }
    func updateViewConstraints() {
        viewController?.setupViewHeight()
    }
    func didTapYoutubeLinkButton() {
        viewController?.moveToYoutube()
    }
    func didTapCloseButton() {
        viewController?.dismiss()
    }
    func didTapStarButton() {
        currentSong.isStar.toggle()
        if currentSong.isStar {
            PersistenceManager.shared.addFavoriteSong(song: currentSong)
        } else {
            PersistenceManager.shared.deleteSong(id: currentSong.id)
        }
        viewController?.setupStarButton(isStar: currentSong.isStar)
    }
}
