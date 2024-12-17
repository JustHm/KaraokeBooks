////
////  RecentSongViewController.swift
////  KaraokeBooks
////
////  Created by 안정흠 on 2023/02/12.
////
//
//import UIKit
//import RxSwift
//import SnapKit
//import ReactorKit
//
//final class RecentSongViewController: UIViewController, View {
//    var disposeBag = DisposeBag()
//    typealias Reactor = RecentSongReactor
//    private lazy var presenter = RecentSongPresenter(viewController: self)
//    private lazy var dateField: UITextField = {
//        let field = UITextField()
//        
//        field.datePickerMonthAndYear(target: self,
//                                     doneAction: #selector(doneAction),
//                                     cancelAction: #selector(cancelAction),
//                                     screenWidth: UIScreen.main.bounds.width)
//        field.text = Date().dateToString(format: "yyyy년 MM월")
//        field.borderStyle = .roundedRect
//        return field
//    }()
//    private lazy var brandSegmentedControl: ClearSegmentedControl = {
//        let segmentedControl = ClearSegmentedControl()
//        BrandType.allCases.enumerated().forEach { (index, value) in
//            segmentedControl.insertSegment(
//                withTitle: value.name,
//                at: index,
//                animated: false)
//        }
//        segmentedControl.selectedSegmentIndex = 0
//        segmentedControl.addTarget(
//            self,
//            action: #selector(valueChangedBrandSegmentedControl),
//            for: .valueChanged
//        )
//        return segmentedControl
//    }()
//    private lazy var recentSongTableView: SongTableView = {
//        let tableView = SongTableView(frame: .zero, style: .plain)
//        tableView.dataSource = presenter
//        tableView.delegate = presenter
//        tableView.register(SongTableViewCell.self,
//                           forCellReuseIdentifier: SongTableViewCell.identifier)
//        return tableView
//    }()
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        presenter.viewDidLoad()
//    }
//    func bind(reactor: RecentSongReactor) {
//        
//    }
//}
//
//extension RecentSongViewController: RecentSongProtocol {
//    func reloadTableView() {
//        recentSongTableView.reloadData()
//    }
//    func setupViews() {
//        view.backgroundColor = .customBackground
//        navigationItem.title = "최신곡"
//        [dateField, recentSongTableView, brandSegmentedControl].forEach {
//            view.addSubview($0)
//        }
//        dateField.snp.makeConstraints {
//            $0.top.equalTo(view.safeAreaLayoutGuide).inset(16.0)
//            $0.right.equalTo(view.safeAreaLayoutGuide).inset(16.0)
//        }
//        brandSegmentedControl.snp.makeConstraints {
//            $0.top.equalTo(dateField.snp.bottom).offset(16.0)
//            $0.left.right.equalToSuperview().inset(16.0)
//        }
//        recentSongTableView.snp.makeConstraints {
//            $0.left.right.bottom.equalToSuperview()
//            $0.top.equalTo(brandSegmentedControl.snp.bottom)
//        }
//    }
//    func moveToDetailViewController(song: Song) {
//        let viewController = SongDetailViewController(song: song)
//        viewController.modalPresentationStyle = .pageSheet
//        present(viewController, animated: true)
//    }
//}
//
//private extension RecentSongViewController {
//    @objc func valueChangedBrandSegmentedControl(_ sender: UISegmentedControl) {
//        let selectedIndex = sender.selectedSegmentIndex
//        let brand = BrandType.allCases[selectedIndex]
//        presenter.valueChangedBrandSegmentedControl(brand: brand)
//    }
//    @objc
//    func cancelAction() {
//        self.dateField.resignFirstResponder()
//    }
//    @objc
//    func doneAction() {
//        if let datePickerView = self.dateField.inputView as? UIDatePicker {
//            let dateString = datePickerView.date.dateToString(format: "yyyy년 MM월")
//            self.dateField.text = dateString
//            presenter.dateChanged(date: datePickerView.date)
//            self.dateField.resignFirstResponder()
//        }
//    }
//}
