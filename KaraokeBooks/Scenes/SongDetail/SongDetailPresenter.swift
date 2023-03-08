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
    private let userDefaults: UserDefaultsManagerProtocol
    private var currentSong: Song
    init(
        viewController: SongDetailProtocol,
        song: Song,
        userDefaults: UserDefaultsManagerProtocol = UserDefaultsManager()
    ) {
        self.viewController = viewController
        self.userDefaults = userDefaults
        self.currentSong = song
    }
    func viewDidLoad() {
        viewController?.setupViews()
        viewController?.setupViewHeight()
        viewController?.setupLinkURL(song: currentSong)
        currentSong.isStar = userDefaults.isFavoriteSong(currentSong)
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
            userDefaults.addFavoriteSong(currentSong)
        } else {
            userDefaults.deleteFavoriteSong(currentSong)
        }
        viewController?.setupStarButton(isStar: currentSong.isStar)
    }
}
