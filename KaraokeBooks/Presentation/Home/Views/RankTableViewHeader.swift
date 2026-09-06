//
//  RankTableViewHeader.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class RankTableViewHeader: UIView {
    private let contentStack = UIStackView()
    var currentDate: BehaviorRelay<RankDateType> = BehaviorRelay(value: .daily)
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: .systemFont(ofSize: 22.0, weight: .bold))
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        label.text = String(localized: "chart.popular")
        return label
    }()
    lazy var dateMenu: UIButton = {
        let button = UIButton()
        let actions = RankDateType.allCases.map { dateType in
            UIAction(title: dateType.localizedTitle, handler: { [weak self] _ in
                button.setTitle(dateType.localizedTitle, for: .normal)
                self?.currentDate.accept(dateType)
            })
        }
        let menu = UIMenu(children: actions)
        button.menu = menu
        button.showsMenuAsPrimaryAction = true
        button.setTitle(RankDateType.daily.localizedTitle, for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: .systemFont(ofSize: 22.0, weight: .bold))
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.numberOfLines = 0
        
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            updateLayout()
        }
    }

    private func setupViews() {
        addSubview(contentStack)
        [dateMenu, titleLabel].forEach { contentStack.addArrangedSubview($0) }
        contentStack.spacing = 8
        contentStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        updateLayout()
    }

    private func updateLayout() {
        let expanded = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        contentStack.axis = expanded ? .vertical : .horizontal
        contentStack.alignment = expanded ? .leading : .center
        dateMenu.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
}

//extension Reactive where Base: UIButton {
////    public var buttonTitle: ControlProperty<String?> {
////        self.
////    }
//    
//    public var value2: ControlProperty<String?> {
//            /*
//            controlProperty(
//                editingEvents: base의 해당 캐치하고 싶은 이벤트
//                getter: subscribe or bind의 onNext에서 보여줄 값
//                setter: 외부에서 onNext()값을 통해 넘어온 값을 ui에 넣어줌
//            )
//            */
//        controlProperty(editingEvents: [.], getter: <#T##(UIControl) -> T#>, setter: <#T##(UIControl, T) -> Void#>)
//        
////            return base.rx.controlProperty<String?>(editingEvents: [.allEditingEvents,.valueChanged]) { textFiled in
////                  // 관찰할 값
////                  textFiled.text
////                
////            } setter: { textFiled, text in   // 외부애서 onNext를 통해 text변수에 값이 전달됨
////                if textFiled.text != text {
////                    textFiled.text = text
////                }
////            }
//        }
//}
