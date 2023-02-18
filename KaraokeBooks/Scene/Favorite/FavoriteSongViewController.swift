//
//  FavoriteSongViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/12.
//

import UIKit
import SnapKit

final class FavoriteSongViewController: UIViewController {
    private lazy var presenter = FavoriteSongPresenter(viewController: self)
    private lazy var brandSegmentedControl: ClearSegmentedControl = {
        let segmentedControl = ClearSegmentedControl()
        BrandType.allCases.enumerated().forEach { (index, value) in
            segmentedControl.insertSegment(
                withTitle: value.replace,
                at: index,
                animated: false)
        }
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(
            self,
            action: #selector(valueChangedBrandSegmentedControl),
            for: .valueChanged
        )
        return segmentedControl
    }()
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(SongTableViewCell.self, forCellReuseIdentifier: SongTableViewCell.identifier)
        tableView.dataSource = presenter
        tableView.delegate = presenter
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()
    private lazy var warningText: UILabel = {
        let label = UILabel()
        label.text = "저장한 애창곡이 없습니다."
        label.font = .systemFont(ofSize: 16.0, weight: .medium)
        label.textColor = .customPrimaryText
        label.isHidden = true
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewDidLoad()
    }
    
}

extension FavoriteSongViewController: FavoriteSongProtocol {
    func setupViews() {
        view.backgroundColor = .customBackground
        navigationItem.title = HomeList.favourite.rawValue
//        navigationItem.rightBarButtonItem = editBarButtonItem
        [tableView, brandSegmentedControl, warningText].forEach {
            view.addSubview($0)
        }
        brandSegmentedControl.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(16.0)
            $0.left.right.equalToSuperview().inset(16.0)
        }
        tableView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(brandSegmentedControl.snp.bottom)
        }
        warningText.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    func isEmptyTableView(isEmpty: Bool) {
        warningText.isHidden = isEmpty
    }
    func reloadTableView() {
        tableView.reloadData()
    }
    func moveToDetailViewController(song: Song) {
        let viewController = SongDetailViewController(song: song)
        viewController.modalPresentationStyle = .pageSheet
        present(viewController, animated: true)
    }
}
private extension FavoriteSongViewController {
    @objc func valueChangedBrandSegmentedControl(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        let brand = BrandType.allCases[selectedIndex]
        presenter.valueChangedBrandSegmentedControl(brand: brand)
    }
}
