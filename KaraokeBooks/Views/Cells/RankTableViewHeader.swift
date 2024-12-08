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
    var currentTitle: BehaviorRelay<String> = BehaviorRelay<String>(value: "일간")
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22.0, weight: .bold)
        label.text = "인기 차트"
        return label
    }()
    lazy var dateMenu: UIButton = {
        let button = UIButton()
        let actions = RankDateType.allCases.map {
            UIAction(title: $0.rawValue, handler: { [weak self] action in
                button.setTitle(action.title, for: .normal)
                self?.currentTitle.accept(action.title)
            })
        }
        let menu = UIMenu(children: actions)
        button.menu = menu
        button.showsMenuAsPrimaryAction = true
        button.setTitle("일간", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 22.0, weight: .bold)
        
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        [dateMenu, titleLabel].forEach {
            addSubview($0)
        }
        dateMenu.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }
        titleLabel.snp.makeConstraints {
            $0.left.equalTo(dateMenu.snp.right).offset(8.0)
            $0.top.bottom.equalToSuperview()
        }
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
