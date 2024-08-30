//
//  SongDetailViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/10.
//

import UIKit
import SnapKit
import SafariServices
// BViewControllerDelegate 프로토콜 정의
protocol SongDetailViewControllerDelegate: AnyObject {
    func didDismiss()
}
final class SongDetailViewController: UIViewController {
    var delegate: SongDetailViewControllerDelegate?
    private var presenter: SongDetailPresenter!
    private var youtubeURL: URL?
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
        button.addTarget(
            self,
            action: #selector(didTapYoutubeLinkButton),
            for: .touchUpInside
        )
        return button
    }()
    private lazy var starButton: UIButton = {
        let button = UIButton()
        let image = UIImage(systemName: "star")
        button.setImage(image, for: .normal)
        button.tintColor = .systemYellow
        button.addTarget(
            self,
            action: #selector(didTapStarButton),
            for: .touchUpInside
        )
        return button
    }()
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setTitle("확인", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.addTarget(
            self,
            action: #selector(didTapCloseButton),
            for: .touchUpInside
        )
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
    
    init(song: Song) {
        super.init(nibName: nil, bundle: nil)
        presenter = SongDetailPresenter(viewController: self, song: song)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.updateViewConstraints()
    }
    
}

extension SongDetailViewController: SongDetailProtocol {
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
    func setupLinkURL(song: Song) {
        switch song.brand {
        case .kumyoung:
            youtubeURL = URL(string: "https://m.youtube.com/@KARAOKEKY/search?query=\(song.no)")
        case .tj:
            youtubeURL = URL(string: "https://m.youtube.com/user/ziller/search?query=\(song.no)")
        }
        songInfoStackView.setupLabelText(song: song)
    }
    func setupStarButton(isStar: Bool) {
        if isStar {
            starButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
        } else {
            starButton.setImage(UIImage(systemName: "star"), for: .normal)
        }
    }
    func dismiss() {
        dismiss(animated: true) {
            self.delegate?.didDismiss()
        }
    }
    func moveToYoutube() {
        guard let url = youtubeURL else { return }
        let viewController = SFSafariViewController(url: url.absoluteURL)
        present(viewController, animated: true)
    }
}

private extension SongDetailViewController {
    @objc func didTapYoutubeLinkButton() {
        presenter.didTapYoutubeLinkButton()
    }
    @objc func didTapStarButton() {
        presenter.didTapStarButton()
    }
    @objc func didTapCloseButton() {
        presenter.didTapCloseButton()
    }
}
