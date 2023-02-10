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
    private lazy var presenter = SongDetailPresenter(viewController: self)
    private var youtubeURL: URL?
    private lazy var brandImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .green
        imageView.clipsToBounds = true
        return imageView
    }()
    private lazy var titleLabel: UIStackView = {
        let stackView = SongDetailStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        return stackView
    }()
    private lazy var youtubeLinkButton: UIButton = {
        let button = UIButton()
        let image = UIImage(systemName: "message")
        button.setImage(image, for: .normal)
        button.addTarget(
            self,
            action: #selector(didTapYoutubeLinkButton),
            for: .touchUpInside
        )
        return button
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        presenter.viewDidLoad()
    }
    func setup(song: Song) {
        switch song.brand {
        case .kumyoung:
            youtubeURL = URL(string: "https://m.youtube.com/@KARAOKEKY/search?query=\(song.no)")
        case .tj:
//https://www.youtube.com/@TJKaraoke/search?query={number}
            youtubeURL = URL(string: "https://m.youtube.com/user/ziller/search?query=\(song.no)")
        }
        //titleLabel.text = song.title
    }
}

extension SongDetailViewController: SongDetailProtocol {
    func setupViews() {
        [brandImage, titleLabel, youtubeLinkButton].forEach {
            view.addSubview($0)
        }
        brandImage.snp.makeConstraints {
            $0.top.left.equalTo(view.safeAreaLayoutGuide).inset(16.0)
            $0.size.equalTo(32.0)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(brandImage)
            $0.left.equalTo(brandImage.snp.right).offset(16.0)
        }
        youtubeLinkButton.snp.makeConstraints {
            $0.top.equalTo(brandImage)
            $0.left.equalTo(titleLabel.snp.right).offset(16.0)
        }
    }
}

private extension SongDetailViewController {
    @objc func didTapYoutubeLinkButton() {
        guard let url = youtubeURL else {
            return
        }
        print(url)
        let viewController = SFSafariViewController(url: url.absoluteURL)
        present(viewController, animated: true)
    }
}


//struct Song: Codable {
//    let brand: BrandType
//    let no: String
//    let title: String
//    let singer: String
//    let composer: String
//    let lyricist: String
//    let release: String
//}
