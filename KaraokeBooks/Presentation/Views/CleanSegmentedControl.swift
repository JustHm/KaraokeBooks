//
//  CleanSegmentedControl.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import UIKit
import RxCocoa
import RxSwift

/// 시스템 `UISegmentedControl`의 외형 변화와 분리된 밑줄형 세그먼트 컨트롤입니다.
final class ClearSegmentedControl: UIControl {
    private let stackView = UIStackView()
    private let selectionIndicator = UIView()
    private var titles: [String] = []
    private var buttons: [UIButton] = []
    private var selectedIndex = UISegmentedControl.noSegment

    var selectedSegmentIndex: Int {
        get { selectedIndex }
        set { selectSegment(at: newValue, sendValueChanged: false) }
    }

    var numberOfSegments: Int { titles.count }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func insertSegment(withTitle title: String?, at segment: Int, animated: Bool) {
        let index = min(max(segment, 0), titles.count)
        titles.insert(title ?? "", at: index)

        if selectedIndex != UISegmentedControl.noSegment, selectedIndex >= index {
            selectedIndex += 1
        }
        rebuildButtons()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard buttons.indices.contains(selectedIndex) else {
            selectionIndicator.isHidden = true
            return
        }

        selectionIndicator.isHidden = false
        let segmentWidth = bounds.width / CGFloat(numberOfSegments)
        selectionIndicator.frame = CGRect(
            x: segmentWidth * CGFloat(selectedIndex),
            y: bounds.height - 2,
            width: segmentWidth,
            height: 2
        )
    }
}

private extension ClearSegmentedControl {
    func configureViews() {
        isAccessibilityElement = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill

        selectionIndicator.backgroundColor = .systemRed

        addSubview(stackView)
        addSubview(selectionIndicator)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func rebuildButtons() {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        buttons = titles.enumerated().map { index, title in
            let button = UIButton(type: .system)
            button.tag = index
            button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.setTitle(title, for: .normal)
            button.accessibilityLabel = title
            button.accessibilityUserInputLabels = [title]
            button.addTarget(self, action: #selector(didTapSegment(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
            return button
        }

        updateButtonAppearance()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    func selectSegment(at index: Int, sendValueChanged: Bool) {
        guard buttons.indices.contains(index), selectedIndex != index else { return }

        selectedIndex = index
        updateButtonAppearance()
        setNeedsLayout()

        if sendValueChanged {
            sendActions(for: .valueChanged)
        }
    }

    func updateButtonAppearance() {
        buttons.enumerated().forEach { index, button in
            let isSelected = index == selectedIndex
            button.setTitleColor(isSelected ? .systemRed : .secondaryLabel, for: .normal)
            button.accessibilityTraits = isSelected ? [.button, .selected] : .button
            button.accessibilityValue = isSelected ? String(localized: "accessibility.selected") : nil
        }
    }

    @objc func didTapSegment(_ sender: UIButton) {
        selectSegment(at: sender.tag, sendValueChanged: true)
    }
}

extension Reactive where Base: ClearSegmentedControl {
    var selectedSegmentIndex: ControlProperty<Int> {
        base.rx.controlProperty(
            editingEvents: .valueChanged,
            getter: { $0.selectedSegmentIndex },
            setter: { control, index in
                control.selectedSegmentIndex = index
            }
        )
    }
}
