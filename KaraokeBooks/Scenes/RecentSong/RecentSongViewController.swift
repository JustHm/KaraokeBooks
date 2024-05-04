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
    private lazy var dateField: UITextField = {
        let field = UITextField()
        field.inputView = currentDatePicker
        field.text = Date().dateToString(format: "yyyy년 MM월")
        field.borderStyle = .roundedRect
        return field
    }()
    private lazy var currentDatePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.locale = Locale(identifier: "ko_KR")
        datePicker.datePickerMode = .init(rawValue: 4269) ?? .date //왜 되는거지..?
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = Date()
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        return datePicker
    }()
    private lazy var brandSegmentedControl: ClearSegmentedControl = {
        let segmentedControl = ClearSegmentedControl()
        BrandType.allCases.enumerated().forEach { (index, value) in
            segmentedControl.insertSegment(
                withTitle: value.name,
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
    private lazy var recentSongTableView: SongTableView = {
        let tableView = SongTableView(frame: .zero, style: .plain)
        tableView.dataSource = presenter
        tableView.delegate = presenter
        tableView.register(SongTableViewCell.self,
                           forCellReuseIdentifier: SongTableViewCell.identifier)
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
    func setupToolBar() {
        let toolBar = UIToolbar()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonHandeler))

        toolBar.items = [flexibleSpace, doneButton]
        // 적절한 사이즈로 toolBar의 크기를 만들어 줍니다.
        toolBar.sizeToFit()

        // textField의 경우 클릭 시 키보드 위에 AccessoryView가 표시된다고 합니다.
        // 현재 inputView를 datePicker로 만들어 줬으니 datePicker위에 표시되겠죠?
        dateField.inputAccessoryView = toolBar
    }
    func setupViews() {
        setupToolBar()
        view.backgroundColor = .customBackground
        navigationItem.title = "최신곡"
        [dateField, recentSongTableView, brandSegmentedControl].forEach {
            view.addSubview($0)
        }
        dateField.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(16.0)
            $0.right.equalTo(view.safeAreaLayoutGuide).inset(16.0)
        }
        brandSegmentedControl.snp.makeConstraints {
            $0.top.equalTo(dateField.snp.bottom).offset(16.0)
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
        dateField.text = date.dateToString(format: "yyyy년 MM월")
    }
    @objc func doneButtonHandeler(_ sender: UIBarButtonItem) {
        dateField.text = currentDatePicker.date.dateToString(format: "yyyy년 MM월")
        presenter.dateChanged(date: currentDatePicker.date)
        // 키보드 내리기
        dateField.resignFirstResponder()
    }
}
