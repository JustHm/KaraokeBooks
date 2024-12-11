//
//  FavoriteSongViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/12.
//

import UIKit
import SnapKit
import ReactorKit

final class FavoriteSongViewController: UIViewController, View {
    typealias Reactor = FavoriteSongReactor
    var disposeBag = DisposeBag()
    
    private lazy var brandSegmentedControl: ClearSegmentedControl = {
        let segmentedControl = ClearSegmentedControl()
        BrandType.allCases.enumerated().forEach { (index, value) in
            segmentedControl.insertSegment(
                withTitle: value.name,
                at: index,
                animated: false)
        }
        segmentedControl.selectedSegmentIndex = 0
        return segmentedControl
    }()
    private lazy var favoriteSongTableView: SongTableView = {
        let tableView = SongTableView(frame: .zero, style: .plain)
        tableView.register(SongTableViewCell.self,
                           forCellReuseIdentifier: SongTableViewCell.identifier)
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
    
    init(reactor: Reactor) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    func bind(reactor: FavoriteSongReactor) {
        brandSegmentedControl.rx.selectedSegmentIndex
            .map{Reactor.Action.brandType(BrandType.allCases[$0])}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        favoriteSongTableView.rx.itemSelected
            .map{Reactor.Action.songDetail($0)}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        favoriteSongTableView.rx.itemDeleted
            .map{Reactor.Action.deleteSong($0)}
            .bind(to: reactor.action)
            .disposed(by:disposeBag)
        
        //State
        reactor.state.observe(on: MainScheduler.instance)
            .map {$0.favoriteSongs}
            .bind(to: favoriteSongTableView.rx.items(cellIdentifier: SongTableViewCell.identifier, cellType: SongTableViewCell.self)) { index, item, cell in
                cell.setup(rank: index, song: item)
            }
            .disposed(by: disposeBag)
        reactor.state.map {$0.isEmpty}
            .distinctUntilChanged()
            .bind { [weak self] in
                self?.warningText.isHidden = !$0
            }
            .disposed(by: disposeBag)
        reactor.state.map {$0.errorDescription}
            .compactMap{$0} //compactMap은 nil만 필터링 하기 때문에 두 번 호출되지 않음.
            .bind { [weak self] in
                self?.showAlert(header: "Error", body: $0)
            }
            .disposed(by: disposeBag)
        reactor.state.compactMap{$0.selectedSong}
            .bind { [weak self] song in
                if let detailReactor = reactor.reactorForSetting() {
                    let songDetailVC = SongDetailViewController(reactor: detailReactor)
                    self?.present(songDetailVC, animated: true)
                }
            }
            .disposed(by: disposeBag)
    }
}


extension FavoriteSongViewController {
    func setupViews() {
        view.backgroundColor = .customBackground
        navigationItem.title = HomeList.favourite.rawValue
        [favoriteSongTableView, brandSegmentedControl, warningText].forEach {
            view.addSubview($0)
        }
        brandSegmentedControl.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(16.0)
            $0.left.right.equalToSuperview().inset(16.0)
        }
        favoriteSongTableView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(brandSegmentedControl.snp.bottom)
        }
        warningText.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    private func showAlert(header: String, body: String) {
        let alert = UIAlertController(title: header, message: body, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true)
    }
}
