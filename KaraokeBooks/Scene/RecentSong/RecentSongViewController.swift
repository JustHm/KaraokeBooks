//
//  RecentSongViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/12.
//

import UIKit
import SnapKit

final class RecentSongViewController: UIViewController {
    private lazy var presenter = RecentSongPresenter(viewController: self)
    private lazy var currentDatePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.locale = Locale(identifier: "ko_KR")
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.maximumDate = Date()
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        return datePicker
    }()
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
    private lazy var recentSongTableView: UITableView = {
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

extension RecentSongViewController: RecentSongProtocol {
    func reloadTableView() {
        recentSongTableView.reloadData()
    }
    func setupViews() {
        view.backgroundColor = .customBackground
        navigationItem.titleView = currentDatePicker
        [recentSongTableView, brandSegmentedControl].forEach {
            view.addSubview($0)
        }
        brandSegmentedControl.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(16.0)
            $0.left.right.equalToSuperview().inset(16.0)
        }
        recentSongTableView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(brandSegmentedControl.snp.bottom)
        }
    }
    func moveToDetailViewController(song: Song) {
        let viewController = SongDetailViewController(song: song)
        viewController.modalPresentationStyle = .pageSheet
        present(viewController, animated: true)
    }
}

private extension RecentSongViewController {
    @objc func valueChangedBrandSegmentedControl(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        let brand = BrandType.allCases[selectedIndex]
        presenter.valueChangedBrandSegmentedControl(brand: brand)
    }
    @objc func dateChanged(sender: UIDatePicker) {
        let date = sender.date
        presenter.dateChanged(date: date)
    }
}
