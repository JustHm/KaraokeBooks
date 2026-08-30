//
//  HomeViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import UIKit
import SnapKit
import RxCocoa
import ReactorKit

final class HomeViewController: UIViewController, View {
    typealias Reactor = HomeReactor

    private let contactEmail = "taggma12@icloud.com"
    
    var disposeBag = DisposeBag()

    private lazy var helpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "questionmark.circle.fill"), for: .normal)
        button.tintColor = .customPrimaryText
        button.accessibilityLabel = "문의하기"
        return button
    }()

    private lazy var appIconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "HomeAppIcon"))
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8.0
        imageView.clipsToBounds = true
        imageView.accessibilityLabel = "노래방BOOK"
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "노래방BOOK"
        label.font = UIFontMetrics(forTextStyle: .title1).scaledFont(
            for: .systemFont(ofSize: 30.0, weight: .bold)
        )
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .customPrimaryText
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var brandStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [appIconImageView, titleLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 10.0
        return stack
    }()

    private lazy var headerStackView: UIStackView = {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [brandStackView, spacer, helpButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 10.0
        return stack
    }()
    
    private lazy var stackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.distribution = .fillEqually
        return stack
    }()
    
    private lazy var favoriteListButton: MoveSceneButton = {
        let button = MoveSceneButton(title: "애창곡", symbol: "star")
        return button
    }()
    
    private lazy var searchButton: MoveSceneButton = {
        let button = MoveSceneButton(title: "노래검색", symbol: "magnifyingglass")
        return button
    }()
    
    private lazy var rankTableHeader = RankTableViewHeader()
    
    private lazy var loadIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .customPrimaryText
        indicator.isHidden = true
        indicator.startAnimating()
        return indicator
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
        return segmentedControl
    }()
    
    private lazy var rankTableView: SongTableView = {
        let tableView = SongTableView(frame: .zero, style: .plain)
        tableView.register(SongTableViewCell.self,
                           forCellReuseIdentifier: SongTableViewCell.identifier)
        return tableView
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

extension HomeViewController {
    func setupViews() {
        [favoriteListButton, searchButton].forEach { stackView.addArrangedSubview($0) }
        helpButton.addTarget(self, action: #selector(didTapHelp), for: .touchUpInside)
        [headerStackView, stackView, rankTableHeader, brandSegmentedControl, rankTableView, loadIndicator].forEach {
            view.addSubview($0)
        }

        headerStackView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(12.0)
            $0.left.right.equalToSuperview().inset(20.0)
        }

        appIconImageView.snp.makeConstraints {
            $0.size.equalTo(32.0)
        }

        helpButton.snp.makeConstraints {
            $0.size.equalTo(44.0)
        }
        
        stackView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16.0)
            $0.top.equalTo(headerStackView.snp.bottom).offset(16.0)
            $0.height.equalTo(120)
        }
        
        rankTableHeader.snp.makeConstraints {
            $0.top.equalTo(stackView.snp.bottom).offset(16.0)
            $0.left.right.equalToSuperview().inset(32.0)
        }
        
        brandSegmentedControl.snp.makeConstraints {
            $0.top.equalTo(rankTableHeader.snp.bottom)
            $0.left.right.equalToSuperview().inset(32.0)
        }
        
        rankTableView.snp.makeConstraints {
            $0.top.equalTo(brandSegmentedControl.snp.bottom).offset(2.0)
            $0.left.right.equalToSuperview().inset(16.0)
            $0.bottom.equalToSuperview()
        }
        loadIndicator.snp.makeConstraints {
            $0.center.equalTo(rankTableView)
        }
    }

    @objc private func didTapHelp() {
        present(ContactSheetViewController(email: contactEmail), animated: true)
    }
}

extension HomeViewController {
    func bind(reactor: HomeReactor) {
        //Action
        brandSegmentedControl.rx.selectedSegmentIndex
            .map{Reactor.Action.brandType(BrandType.allCases[$0])}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        rankTableView.rx.itemSelected
            .map{Reactor.Action.songDetail($0)}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        rankTableHeader.currentTitle
            .map {Reactor.Action.rankDateType($0)}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        favoriteListButton.rx.tap
            .withUnretained(self)
            .bind { owner, _ in
                let reactor = FavoriteSongReactor()
                let vc = FavoriteSongViewController(reactor: reactor)
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        searchButton.rx.tap
            .withUnretained(self)
            .bind { owner, _ in
                let reactor = SearchResultReactor()
                let vc = SearchResultViewController(reactor: reactor)
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        //State
        reactor.state.observe(on: MainScheduler.instance)
            .map{$0.isLoading}
            .distinctUntilChanged()
            .withUnretained(self)
            .bind { owner, isLoading in
                owner.loadIndicator.isHidden = !isLoading
                isLoading ? owner.loadIndicator.startAnimating() : owner.loadIndicator.stopAnimating()
            }
            .disposed(by: disposeBag)
        reactor.state.observe(on: MainScheduler.instance)
            .map{ $0.popularList }
            .bind(to: rankTableView.rx.items(cellIdentifier: SongTableViewCell.identifier, cellType: SongTableViewCell.self)) { index, item, cell in
                cell.setup(rank: index, song: item)
            }
            .disposed(by: disposeBag)
        reactor.state.compactMap{$0.selectedSong}
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind { owner, song in
                if let detailReactor = reactor.reactorForSetting(song: song) {
                    let songDetailVC = SongDetailViewController(reactor: detailReactor)
                    owner.present(songDetailVC, animated: true)
                }
            }
            .disposed(by: disposeBag)
    }
    
    private func showAlert(header: String, body: String) {
        let alert = UIAlertController(title: header, message: body, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true)
    }
}

private final class ContactSheetViewController: UIViewController {
    private let email: String

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "문의하기"
        label.font = .preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .customPrimaryText
        return label
    }()

    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.text = email
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var openMailButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "envelope.fill"), for: .normal)
        button.setTitle("  메일 앱 열기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = .systemPink
        button.layer.cornerRadius = 12.0
        button.addTarget(self, action: #selector(didTapOpenMail), for: .touchUpInside)
        return button
    }()

    private lazy var copyEmailButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        button.setTitle("  메일 주소 복사", for: .normal)
        button.setTitleColor(.customPrimaryText, for: .normal)
        button.tintColor = .customPrimaryText
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = .tertiarySystemFill
        button.layer.cornerRadius = 12.0
        button.addTarget(self, action: #selector(didTapCopyEmail), for: .touchUpInside)
        return button
    }()

    init(email: String) {
        self.email = email
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        preferredContentSize = CGSize(width: 0, height: 280.0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSheet()
        setupViews()
    }

    private func configureSheet() {
        guard #available(iOS 15.0, *), let sheet = sheetPresentationController else { return }

        let contactDetentIdentifier = UISheetPresentationController.Detent.Identifier("contact")
        if #available(iOS 16.0, *) {
            sheet.detents = [
                .custom(identifier: contactDetentIdentifier) { context in
                    min(280.0, context.maximumDetentValue)
                }
            ]
            sheet.selectedDetentIdentifier = contactDetentIdentifier
        } else {
            sheet.detents = [.medium()]
            sheet.selectedDetentIdentifier = .medium
        }
        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = 24.0
    }

    private func setupViews() {
        view.backgroundColor = .customForeground
        [titleLabel, emailLabel, openMailButton, copyEmailButton].forEach {
            view.addSubview($0)
        }
        titleLabel.snp.makeConstraints {
            $0.top.left.right.equalTo(view.safeAreaLayoutGuide).inset(20.0)
        }
        emailLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6.0)
            $0.left.right.equalToSuperview().inset(20.0)
        }
        openMailButton.snp.makeConstraints {
            $0.top.equalTo(emailLabel.snp.bottom).offset(22.0)
            $0.left.right.equalToSuperview().inset(20.0)
            $0.height.greaterThanOrEqualTo(52.0)
        }
        copyEmailButton.snp.makeConstraints {
            $0.top.equalTo(openMailButton.snp.bottom).offset(10.0)
            $0.left.right.equalToSuperview().inset(20.0)
            $0.height.greaterThanOrEqualTo(52.0)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16.0)
        }
    }

    @objc private func didTapOpenMail() {
        guard let url = URL(string: "mailto:\(email)") else { return }
        UIApplication.shared.open(url)
    }

    @objc private func didTapCopyEmail() {
        UIPasteboard.general.string = email
        copyEmailButton.setTitle("  복사됨", for: .normal)
    }
}
