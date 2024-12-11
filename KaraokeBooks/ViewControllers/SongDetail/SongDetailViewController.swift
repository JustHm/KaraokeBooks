//
//  SongDetailViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/10.
//

import UIKit
import SnapKit
import ReactorKit
import RxSwift
import SafariServices

final class SongDetailViewController: UIViewController, View {
    var disposeBag = DisposeBag()
    typealias Reactor = SongDetailReactor
    private lazy var titleImage: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "music.note.house"))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    private lazy var songInfoStackView: SongInfoStackView = {
        let stackView = SongInfoStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8.0
        stackView.distribution = .equalSpacing
        return stackView
    }()
    private lazy var youtubeLinkButton: UIButton = {
        let button = UIButton()
        let image = UIImage(systemName: "play.rectangle.fill")
        button.setImage(image, for: .normal)
        return button
    }()
    private lazy var starButton: UIButton = {
        let button = UIButton()
        let image = UIImage(systemName: "star")
        button.setImage(image, for: .normal)
        button.tintColor = .systemYellow
        return button
    }()
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setTitle("확인", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        return button
    }()
    private lazy var interactionButtonStackView: UIStackView = {
        let stackView = UIStackView(
            arrangedSubviews: [youtubeLinkButton, starButton, closeButton]
        )
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = 20.0
        return stackView
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
        reactor?.action.onNext(.viewDidLoad)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupViewHeight()
    }
    func bind(reactor: SongDetailReactor) {
        starButton.rx.tap
            .map{ Reactor.Action.starTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        youtubeLinkButton.rx.tap
            .map{ Reactor.Action.youtubeTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        closeButton.rx.tap
            .map{ Reactor.Action.closeTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reactor.state.map{$0.isStar}
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind { owner, isStar in
                let symbol = isStar ? "star.fill" : "star"
                owner.starButton.setImage(UIImage(systemName: symbol), for: .normal)
            }
            .disposed(by: disposeBag)
        reactor.state.compactMap{$0.youtubeURL}
            .distinctUntilChanged()
            .withUnretained(self)
            .bind { owner, url in
                let viewController = SFSafariViewController(url: url.absoluteURL)
                owner.present(viewController, animated: true)
            }
            .disposed(by: disposeBag)
        reactor.state.map{$0.errorMessage}
            .compactMap{$0} //compactMap은 nil만 필터링 하기 때문에 두 번 호출되지 않음.
            .withUnretained(self)
            .bind { owner, msg in
                owner.showAlert(header: "Error", body: msg)
            }
            .disposed(by: disposeBag)
        reactor.state.map{$0.song}
            .distinctUntilChanged()
            .withUnretained(self)
            .bind { owner, song in
                owner.songInfoStackView.setupLabelText(song: song)
            }
            .disposed(by: disposeBag)
        reactor.state.filter{$0.isDismiss}
            .withUnretained(self)
            .bind { owner, isDismiss in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
}

extension SongDetailViewController {
    func setupViewHeight() {
        // 모달 컨트롤러용 iOS 13에 도입된 최상단까지의 거리
        let TOP_CARD_DISTANCE: CGFloat = 40.0
        //SnapKit으로 레이아웃이 잡혀도 각 뷰에 constraints값은 변경이 안되어 있다. 근데 왜 배치는 잘됨?
        //그래서 layoutIfNeeded를 호출해서 뷰를 다시 계산하면 변경된 값이 나온다.
        songInfoStackView.layoutIfNeeded()
        let viewHeight: CGFloat = songInfoStackView.frame.height + (songInfoStackView.frame.maxY * 1.5)
        view.frame.size.height = viewHeight
        // reposition the view (if not it will be near the top)
        view.frame.origin.y = UIScreen.main.bounds.height - viewHeight - TOP_CARD_DISTANCE
        view.layoutIfNeeded()
    }
    
    func setupViews() {
        view.backgroundColor = .customBackground
        view.layer.cornerRadius = 15.0
        [
            titleImage,
            songInfoStackView,
            interactionButtonStackView
        ].forEach {
            view.addSubview($0)
        }
        titleImage.snp.makeConstraints {
            $0.size.equalTo(32.0)
            $0.top.left.equalToSuperview().inset(16.0)
        }
        interactionButtonStackView.snp.makeConstraints {
            $0.top.right.equalToSuperview().inset(16.0)
        }
        songInfoStackView.snp.makeConstraints {
            $0.top.equalTo(interactionButtonStackView.snp.bottom).offset(16.0)
            $0.left.right.equalToSuperview().inset(16.0)
        }
    }
    private func showAlert(header: String, body: String) {
        let alert = UIAlertController(title: header, message: body, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true)
    }
}
