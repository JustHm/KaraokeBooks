//
//  SearchResultViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/16.
//

import UIKit
import SnapKit

final class SearchResultViewController: UIViewController {
    private lazy var presenter = SearchResultPresenter(viewController: self)
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController()
        searchController.searchBar.delegate = presenter
        return searchController
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
    private lazy var resultTableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = presenter
        tableView.delegate = presenter
        tableView.register(SongTableViewCell.self, forCellReuseIdentifier: SongTableViewCell.identifier)
        return tableView
    }()
    private lazy var warningText: UILabel = {
        let label = UILabel()
        label.text = "검색 결과가 없습니다."
        label.font = .systemFont(ofSize: 16.0, weight: .medium)
        label.sizeToFit()
        label.textColor = .customPrimaryText
        label.isHidden = true
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewDidLoad()
    }
}

extension SearchResultViewController: SearchResultProtocol {
    func setupNavigationTitle(title: String) {
        navigationItem.title = title
        searchController.searchBar.placeholder = title
    }
    func isEmptyTableView(isEmpty: Bool) {
        warningText.isHidden = isEmpty
    }
    func setupViews() {
        view.backgroundColor = .customBackground
        [resultTableView, brandSegmentedControl, warningText].forEach {
            view.addSubview($0)
        }
        brandSegmentedControl.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(16.0)
            $0.left.right.equalToSuperview().inset(16.0)
        }
        resultTableView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(brandSegmentedControl.snp.bottom)
        }
        warningText.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    func setupNavigationBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.titleMenuProvider = { suggestions in
            var finalMenuElements = suggestions
            finalMenuElements.append(UICommand(title: "노래 검색",
                                               image: UIImage(systemName: "heart"),
                                               action: #selector(self.didTapSongFilter(_:))))
            finalMenuElements.append(UICommand(title: "가수 검색",
                                               image: UIImage(systemName: "message"),
                                               action: #selector(self.didTapSingerFilter(_:))))
            return UIMenu(children: finalMenuElements)
        }
    }
    func reloadTableView() {
        resultTableView.reloadData()
    }
    func moveToDetailViewController(song: Song) {
        let viewController = SongDetailViewController(song: song)
        viewController.modalPresentationStyle = .pageSheet
        present(viewController, animated: true)
    }
}
private extension SearchResultViewController {
    @objc func valueChangedBrandSegmentedControl(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        let brand = BrandType.allCases[selectedIndex]
        presenter.valueChangedBrandSegmentedControl(brand: brand)
    }
    @objc func didTapSingerFilter(_ sender: UICommand) {
        presenter.didTapSearchFilterButton(title: sender.title)
    }
    @objc func didTapSongFilter(_ sender: UICommand) {
        presenter.didTapSearchFilterButton(title: sender.title)
    }
}
