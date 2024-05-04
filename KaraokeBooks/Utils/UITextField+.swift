//
//  UITextField+.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 5/4/24.
//

import UIKit
//https://programmingwithswift.com/add-uidatepicker-in-a-uitextfield-with-swift/
extension UITextField {
    func datePickerMonthAndYear<T>(target: T,
                       doneAction: Selector,
                       cancelAction: Selector,
                       screenWidth: CGFloat) {
        // Create Toolbar Button
        func buttonItem(withSystemItemStyle style: UIBarButtonItem.SystemItem) -> UIBarButtonItem {
            let buttonTarget = style == .flexibleSpace ? nil : target
            let action: Selector? = {
                switch style {
                case .cancel:
                    return cancelAction
                case .done:
                    return doneAction
                default:
                    return nil
                }
            }()
            
            let barButtonItem = UIBarButtonItem(barButtonSystemItem: style,
                                                target: buttonTarget,
                                                action: action)
            
            return barButtonItem
        }
        // Setting up the UIDatePicker and the UIToolBar
        let datePicker = UIDatePicker(frame: CGRect(x: 0,
                                                    y: 0,
                                                    width: screenWidth,
                                                    height: 216))
        
        datePicker.locale = Locale(identifier: "ko_KR")
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = Date()
        datePicker.datePickerMode = .init(rawValue: 4269) ?? .date /*왜 되는거지..?*/
        self.inputView = datePicker
        
        let toolBar = UIToolbar(frame: CGRect(x: 0,
                                              y: 0,
                                              width: screenWidth,
                                              height: 44))
        toolBar.setItems([buttonItem(withSystemItemStyle: .cancel),
                          buttonItem(withSystemItemStyle: .flexibleSpace),
                          buttonItem(withSystemItemStyle: .done)],
                         animated: true)
        self.inputAccessoryView = toolBar
    }
}
