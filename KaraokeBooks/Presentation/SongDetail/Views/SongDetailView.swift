//
//  SongDetailView.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/09/06.
//

import SwiftUI
import UIKit

final class SongDetailViewModel: ObservableObject {
    @Published var state: SongDetailReactor.State

    init(state: SongDetailReactor.State) { self.state = state }
}

struct SongDetailView: View {
    @ObservedObject var model: SongDetailViewModel
    var onAction: (SongDetailReactor.Action) -> Void = { _ in }
    var onEditingChanged: (Bool) -> Void = { _ in }
    @State private var isEditing = false
    @State private var draft = ""
    @State private var inlineBannerHeight: CGFloat = 0.0
    @FocusState private var editorFocused: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    // Adjust these values to tune the entire sheet in Preview.
    private let horizontalPadding: CGFloat = 24
    private let sectionSpacing: CGFloat = 24
    private var state: SongDetailReactor.State { model.state }
    private var secondary: Color { Color(uiColor: .customSecondaryText ?? .secondaryLabel) }

    var body: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, horizontalPadding).padding(.top, 16).padding(.bottom, 16)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: sectionSpacing) {
                        SongInfoStackView(song: state.song)
                        memoSection.id("memo")
                        if !isEditing {
                            InlineBannerAd(height: $inlineBannerHeight)
                                .frame(maxWidth: .infinity)
                                .frame(height: inlineBannerHeight)
                        }
                        credits
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 24)
                }
                .task(id: isEditing) {
                    guard isEditing else { return }
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    guard !Task.isCancelled else { return }
                    editorFocused = true
                    withAnimation { proxy.scrollTo("memo", anchor: .top) }
                }
            }
            if !isEditing {
                actions.padding(.horizontal, horizontalPadding).padding(.top, 12).padding(.bottom, 16)
            }
        }
        .background(Color(uiColor: .customForeground ?? .systemBackground).ignoresSafeArea())
        .onAppear { draft = state.memo ?? "" }
        .onChange(of: state.memo) { memo in
            if !isEditing { draft = memo ?? "" }
        }
        .onChange(of: state.isStar) { isStar in
            if !isStar { finishEditing() }
        }
        .onChange(of: editorFocused) { focused in
            guard focused, state.isStar, !isEditing else { return }
            isEditing = true
            onEditingChanged(true)
        }
        .onChange(of: state.memoSaveRevision) { _ in finishEditing() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "music.note.house.fill")
                .font(.title3)
                .foregroundColor(.pink)
                .accessibilityHidden(true)
            Text("\(state.song.brand.name) · \(state.song.no)")
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier("songDetail.number")
            Spacer(minLength: 4)
            if isEditing {
                Button("저장") { onAction(.saveMemo(draft)) }
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("memo.save")
            }
        }
        .tint(.pink)
    }

    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("나만의 메모", systemImage: "note.text")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(secondary)
            if state.isStar {
                ZStack(alignment: .topLeading) {
                    memoInput
                        .frame(height: isEditing ? 200 : 80)
                        .accessibilityLabel("나만의 메모 입력")
                        .accessibilityIdentifier("memo.input")
                    if draft.isEmpty {
                        Text(String(localized: "memo.placeholder"))
                            .font(.body)
                            .foregroundColor(secondary)
                            .padding(.horizontal, 5)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                .padding(8)
                .background(Color(uiColor: .customBackground ?? .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Text(String(localized: "memo.favoriteRequired"))
                    .font(.caption)
                    .foregroundColor(secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(uiColor: .customBackground ?? .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    @ViewBuilder private var memoInput: some View {
        if #available(iOS 16.0, *) {
            TextEditor(text: $draft)
                .font(.body)
                .focused($editorFocused)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
        } else {
            ClearMemoTextEditor(text: $draft, isFocused: $editorFocused)
        }
    }

    private var credits: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(format: String(localized: "metadata.composer"), state.song.composer))
            Text(String(format: String(localized: "metadata.lyricist"), state.song.lyricist))
        }
        .font(.caption)
        .foregroundColor(secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var actions: some View {
        if typeSize.isAccessibilitySize {
            VStack(spacing: 10) { actionButtons }
        } else {
            HStack(spacing: 10) { actionButtons }
        }
    }

    @ViewBuilder private var actionButtons: some View {
        Button { onAction(.youtubeTapped) } label: {
            Label(String(localized: "action.showYouTube"), systemImage: "play.rectangle.fill")
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.red)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        Button { onAction(.starTapped) } label: {
            Label(String(localized: state.isStar ? "favorite.remove" : "favorite.add"),
                  systemImage: state.isStar ? "star.fill" : "star")
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color(uiColor: .customBackground ?? .secondarySystemBackground))
            .foregroundColor(Color(uiColor: .customPrimaryText ?? .label))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityAddTraits(state.isStar ? .isSelected : [])
    }

    private func finishEditing() {
        draft = state.memo ?? ""
        editorFocused = false
        isEditing = false
        onEditingChanged(false)
    }
}

/// Keep the memo's own background visible on iOS 15 as well.
private struct ClearMemoTextEditor: UIViewRepresentable {
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

private struct InlineBannerAd: UIViewRepresentable {
    @Binding var height: CGFloat

    func makeUIView(context: Context) -> InlineBannerAdView {
        let view = InlineBannerAdView()
        let height = $height
        view.onHeightChanged = { newHeight in
            DispatchQueue.main.async {
                height.wrappedValue = newHeight
            }
        }
        return view
    }

    func updateUIView(_ uiView: InlineBannerAdView, context: Context) {}
}

struct SongDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            preview(memo: "키 -2 · 후렴은 힘 빼고 부르기")
                .previewDisplayName("메모 있는 곡")
            preview(memo: nil)
                .preferredColorScheme(.dark)
                .previewDisplayName("빈 메모 · 다크 모드")
        }
        .previewLayout(.fixed(width: 390, height: 460))
    }

    private static func preview(memo: String?) -> some View {
        let song = Song(brand: .tj, no: "14515", title: "응급실(쾌걸춘향OST)", singer: "izi",
                        composer: "신동우", lyricist: "신동우", release: "", isStar: true, memo: memo)
        return SongDetailView(model: SongDetailViewModel(state: .init(isStar: true, memo: memo, song: song)))
    }
}
