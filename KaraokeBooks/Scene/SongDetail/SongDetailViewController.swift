//
//  SongDetailViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/10.
//

import UIKit
import SnapKit
import SafariServices

final class SongDetailViewController: UIViewController {
    private var presenter: SongDetailPresenter!
    private var youtubeURL: URL?
    private lazy var brandImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .green
        imageView.clipsToBounds = true
        return imageView
    }()
    private lazy var descriptionStackView: SongDetailStackView = {
        let stackView = SongDetailStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 5.0
        stackView.distribution = .equalSpacing
        return stackView
    }()
    private lazy var youtubeLinkButton: UIButton = {
        let button = UIButton()
        let image = UIImage(systemName: "link")
        button.setImage(image, for: .normal)
        button.tintColor = .systemBlue
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
    private lazy var buttonStackView: UIStackView = {
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
        // distance to top introduced in iOS 13 for modal controllers
        // they're now "cards"
        let TOP_CARD_DISTANCE: CGFloat = 40.0
        //SnapKit으로 레이아웃이 잡혀도 각 뷰에 constraints값은 변경이 안되어 있다. 근데 왜 배치는 잘됨?
        //그래서 layoutIfNeeded를 호출해서 뷰를 다시 계산하면 변경된 값이 나온다.
        descriptionStackView.layoutIfNeeded()
        let viewHeight: CGFloat = descriptionStackView.frame.height + (descriptionStackView.frame.maxY * 2)
        view.frame.size.height = viewHeight
        // reposition the view (if not it will be near the top)
        view.frame.origin.y = UIScreen.main.bounds.height - viewHeight - TOP_CARD_DISTANCE
        view.layoutIfNeeded()
    }
    func setupViews() {
        view.backgroundColor = .customBackground
        view.layer.cornerRadius = 15.0
        [
            brandImage,
            descriptionStackView,
            buttonStackView
        ].forEach {
            view.addSubview($0)
        }
        brandImage.snp.makeConstraints {
            $0.size.equalTo(32.0)
            $0.top.left.equalToSuperview().inset(16.0)
        }
        buttonStackView.snp.makeConstraints {
            $0.top.right.equalToSuperview().inset(16.0)
        }
        descriptionStackView.snp.makeConstraints {
            $0.top.equalTo(buttonStackView.snp.bottom).offset(16.0)
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
        descriptionStackView.setupLabelText(song: song)
    }
    func setupStarButton(isStar: Bool) {
        if isStar {
            starButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
        } else {
            starButton.setImage(UIImage(systemName: "star"), for: .normal)
        }
    }
    func dismiss() {
        dismiss(animated: true)
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
