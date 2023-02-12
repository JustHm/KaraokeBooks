//
//  FavoriteSongViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/12.
//

import UIKit

final class FavoriteSongViewController: UIViewController {
    private lazy var presenter = FavoriteSongPresenter(viewController: self)
    private lazy var editBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(
            title: "Edit",
            style: .plain,
            target: self,
            action: #selector(didTapEditButton)
        )
        return barButtonItem
    }()
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(SongTableViewCell.self, forCellReuseIdentifier: SongTableViewCell.identifier)
        tableView.dataSource = presenter
        tableView.delegate = presenter
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = .customBackground
        return tableView
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewDidLoad()
    }
    
}

extension FavoriteSongViewController: FavoriteSongProtocol {
    func setupViews() {
        view.backgroundColor = .customBackground
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(16.0)
        }
    }
    func reloadTableView() {
        tableView.reloadData()
    }
}
private extension FavoriteSongViewController {
    @objc func didTapEditButton() {
        presenter.didTapEditButton()
    }
}
