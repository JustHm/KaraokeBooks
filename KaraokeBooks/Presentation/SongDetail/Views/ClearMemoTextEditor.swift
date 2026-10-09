//
//  ClearMemoTextEditor.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/09/06.
//

import SwiftUI
import UIKit

/// Keep the memo's own background visible on iOS 15 as well.
struct ClearMemoTextEditor: UIViewRepresentable {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.backgroundColor = .clear
        view.font = .preferredFont(forTextStyle: .body)
        view.adjustsFontForContentSizeCategory = true
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.parent = self
        if view.text != text { view.text = text }
        if isFocused.wrappedValue, !view.isFirstResponder {
            view.becomeFirstResponder()
        } else if !isFocused.wrappedValue, view.isFirstResponder {
            view.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: ClearMemoTextEditor
        init(parent: ClearMemoTextEditor) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) { parent.text = textView.text }
        func textViewDidBeginEditing(_ textView: UITextView) { parent.isFocused.wrappedValue = true }
        func textViewDidEndEditing(_ textView: UITextView) { parent.isFocused.wrappedValue = false }
    }
}
