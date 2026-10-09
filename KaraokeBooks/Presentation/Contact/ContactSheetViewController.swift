//
//  ContactSheetViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import UIKit
import SnapKit

final class ContactSheetViewController: UIViewController {
    private let email: String
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "contact.title")
        label.font = .preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = .customPrimaryText
        return label
    }()

    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.text = email
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var openMailButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "envelope.fill"), for: .normal)
        button.setTitle("  " + String(localized: "action.openMail"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.backgroundColor = .systemPink
        button.layer.cornerRadius = 12.0
        button.addTarget(self, action: #selector(didTapOpenMail), for: .touchUpInside)
        return button
    }()

    private lazy var copyEmailButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        button.setTitle("  " + String(localized: "action.copyEmail"), for: .normal)
        button.setTitleColor(.customPrimaryText, for: .normal)
        button.tintColor = .customPrimaryText
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            configureSheet()
        }
    }

    private func configureSheet() {
        guard #available(iOS 15.0, *), let sheet = sheetPresentationController else { return }

        let contactDetentIdentifier = UISheetPresentationController.Detent.Identifier("contact")
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            sheet.detents = [.large()]
            sheet.selectedDetentIdentifier = .large
        } else if #available(iOS 16.0, *) {
            sheet.detents = [
                .custom(identifier: contactDetentIdentifier) { context in
                    min(280.0, context.maximumDetentValue)
                },
                .large()
            ]
            sheet.selectedDetentIdentifier = contactDetentIdentifier
        } else {
            sheet.detents = [.medium(), .large()]
            sheet.selectedDetentIdentifier = .medium
        }
        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = 24.0
    }

    private func setupViews() {
        view.backgroundColor = .customForeground
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        scrollView.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = 10
        [titleLabel, emailLabel, openMailButton, copyEmailButton].forEach {
            contentStack.addArrangedSubview($0)
        }
        contentStack.setCustomSpacing(6, after: titleLabel)
        contentStack.setCustomSpacing(22, after: emailLabel)
        contentStack.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide).inset(20)
            $0.width.equalTo(scrollView.frameLayoutGuide).offset(-40)
        }
        [openMailButton, copyEmailButton].forEach { button in
            button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(52) }
        }
    }

    @objc private func didTapOpenMail() {
        guard let url = URL(string: "mailto:\(email)") else { return }
        UIApplication.shared.open(url)
    }

    @objc private func didTapCopyEmail() {
        UIPasteboard.general.string = email
        copyEmailButton.setTitle("  " + String(localized: "action.copied"), for: .normal)
    }
}
