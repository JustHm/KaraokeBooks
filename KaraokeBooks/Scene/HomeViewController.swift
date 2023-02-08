//
//  HomeViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import UIKit
import SnapKit

class HomeViewController: UIViewController {
    private lazy var presenter = HomePresenter(viewController: self)
    private lazy var brandSegmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl()
        BrandType.allCases.enumerated().forEach { (index, value) in
            segmentedControl.insertSegment(withTitle: value.replace,
                                           at: index,
                                           animated: true)
        }
        segmentedControl.sizeToFit()
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
        tableView.register(RankTableViewCell.self, forCellReuseIdentifier: RankTableViewCell.identifier)
        tableView.register(RankTableViewHeader.self, forHeaderFooterViewReuseIdentifier: RankTableViewHeader.identifier)
        tableView.dataSource = presenter
        tableView.delegate = presenter
//        tableView.insetsContentViewsToSafeArea = true
        return tableView
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewDidLoad()
    }


}

extension HomeViewController: HomeProtocol {
    func reloadTableView() {
        tableView.reloadData()
    }
    
    func setupViews() {
        [brandSegmentedControl, tableView].forEach {
            view.addSubview($0)
        }
        brandSegmentedControl.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16.0)
            $0.top.equalTo(view.safeAreaLayoutGuide)//.inset(16.0)
        }
        tableView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(brandSegmentedControl.snp.bottom).offset(8.0)
            $0.bottom.equalToSuperview()
        }
    }

    func setupNavigationBar() {
        navigationItem.title = "노래방 책"
//        let view = File()
//        view.setupLayout()
//        navigationItem.titleView = view
    }

}

private extension HomeViewController {
    @objc func valueChangedBrandSegmentedControl(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        let brand = BrandType.allCases[selectedIndex]
        presenter.brandSelected = brand
    }
    @objc func valueChangedDateSegmentedControl(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        let date = RankDateType.allCases[selectedIndex]
        presenter.dateSelected = date
    }
}
