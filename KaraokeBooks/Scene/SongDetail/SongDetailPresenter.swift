//
//  SongDetailPresenter.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/10.
//

import Foundation

protocol SongDetailProtocol: AnyObject {
    func setupViews()
    func setupViewHeight()
}

final class SongDetailPresenter {
    private weak var viewController: SongDetailProtocol?
    
    init(viewController: SongDetailProtocol) {
        self.viewController = viewController
    }
    func viewDidLoad() {
        viewController?.setupViews()
        viewController?.setupViewHeight()
    }
    func updateViewConstraints() {
        viewController?.setupViewHeight()
    }
}
