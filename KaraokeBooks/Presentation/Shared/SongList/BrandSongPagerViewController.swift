//
//  BrandSongPagerViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/09/05.
//

import UIKit
import SnapKit
import RxSwift

struct SongListPageState: Equatable {
    var songs: [Song] = []
    var hasLoaded = false
    var isLoading = false
    var errorDescription: String?
}

/// Each brand keeps its own table, scroll position and ad placement throughout paging.
final class BrandSongPagerViewController: UIViewController {
    let selectedBrand = PublishSubject<BrandType>()
    let selectedSong = PublishSubject<Song>()
    let selectedSongsChanged = PublishSubject<[Song]>()
    private let pages: [BrandSongPageViewController]
    private let pager = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    private var selectedIndex = 0
    private var isTransitioning = false
    private var queuedBrand: BrandType?
    private var isVisible = false

    init(emptyMessage: String? = nil) {
        pages = BrandType.allCases.map {
            BrandSongPageViewController(brand: $0, emptyMessage: emptyMessage)
        }
        super.init(nibName: nil, bundle: nil)
        pages.forEach { page in
            page.onSelect = { [weak self] in self?.selectedSong.onNext($0) }
            page.onSelectionChanged = { [weak self] in self?.publishSelectedSongs() }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(pager)
        view.addSubview(pager.view)
        pager.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        pager.didMove(toParent: self)
        pager.dataSource = self
        pager.delegate = self
        pager.setViewControllers([pages[selectedIndex]], direction: .forward, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isVisible = true
        updateAdVisibility()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isVisible = false
        updateAdVisibility()
    }

    func render(_ state: SongListPageState, for brand: BrandType) {
        pages.first { $0.brand == brand }?.render(state)
    }

    func setTableEditing(_ editing: Bool, animated: Bool) {
        pages.forEach { $0.setTableEditing(editing, animated: animated) }
        if !editing {
            pages.forEach { $0.clearSelection() }
        }
        publishSelectedSongs()
    }

    var selectedSongs: [Song] {
        pages.flatMap(\.selectedSongs)
    }

    func select(_ brand: BrandType) {
        loadViewIfNeeded()
        guard let index = pages.firstIndex(where: { $0.brand == brand }) else { return }
        if isTransitioning {
            queuedBrand = brand
            return
        }
        guard index != selectedIndex else { return }
        isTransitioning = true
        pager.setViewControllers([pages[index]], direction: index > selectedIndex ? .forward : .reverse,
                                 animated: isVisible) { [weak self] _ in
            guard let self else { return }
            self.selectedIndex = index
            self.finishTransition()
        }
    }

    private func finishTransition() {
        isTransitioning = false
        updateAdVisibility()
        if let queuedBrand {
            self.queuedBrand = nil
            select(queuedBrand)
        }
    }

    private func publishSelectedSongs() {
        selectedSongsChanged.onNext(selectedSongs)
    }

    private func updateAdVisibility() {
        // Detach the outgoing ad before enabling the settled page. An adjacent page
        // prepared by UIPageViewController never registers an offscreen ad view.
        for (index, page) in pages.enumerated() where index != selectedIndex || !isVisible {
            page.setAdActive(false)
        }
        if isVisible { pages[selectedIndex].setAdActive(true) }
    }
}

extension BrandSongPagerViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(where: { $0 === viewController }), index > 0 else { return nil }
        return pages[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(where: { $0 === viewController }), index + 1 < pages.count else { return nil }
        return pages[index + 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            willTransitionTo pendingViewControllers: [UIViewController]) {
        // Do not reset UITableView's editing gestures during an interactive pan.
        // On iOS 17 that can interrupt the page controller before its completion.
        isTransitioning = true
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let visible = pageViewController.viewControllers?.first,
           let index = pages.firstIndex(where: { $0 === visible }) {
            selectedIndex = index
        }
        // A segment tap received during a drag wins over the drag's final selection.
        if queuedBrand == nil { selectedBrand.onNext(pages[selectedIndex].brand) }
        finishTransition()
    }
}

private final class BrandSongPageViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching {
    let brand: BrandType
    var onSelect: ((Song) -> Void)?
    var onSelectionChanged: (() -> Void)?
    private let emptyMessage: String?
    private let tableView = SongTableView(frame: .zero, style: .plain)
    private let indicator = UIActivityIndicatorView(style: .large)
    private let messageLabel = UILabel()
    private var state = SongListPageState()
    private var items: [SongListDisplayItem] = []
    private var selectedSongIDs = Set<String>()
    private var isAdActive = false
    private lazy var ads: NativeAdPlacementController = {
        let placement = NativeAdPlacementController(rootViewController: self)
        placement.onAvailabilityChanged = { [weak self] in self?.updateItems() }
        return placement
    }()

    init(brand: BrandType, emptyMessage: String?) {
        self.brand = brand
        self.emptyMessage = emptyMessage
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackground
        tableView.accessibilityIdentifier = "songs.\(brand.rawValue)"
        tableView.register(SongTableViewCell.self, forCellReuseIdentifier: SongTableViewCell.identifier)
        tableView.register(NativeAdTableViewCell.self, forCellReuseIdentifier: NativeAdTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.prefetchDataSource = self
        tableView.allowsMultipleSelectionDuringEditing = true
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        [tableView, indicator, messageLabel].forEach { view.addSubview($0) }
        // Keep the side gutters inside the native pager's gesture area. Row swipes
        // can keep their delete behavior even when favorites fill the entire screen.
        tableView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        indicator.snp.makeConstraints { $0.center.equalToSuperview() }
        messageLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        updateContent()
    }

    func render(_ state: SongListPageState) {
        guard self.state != state else { return }
        self.state = state
        if isViewLoaded { updateContent() }
    }

    func setTableEditing(_ editing: Bool, animated: Bool) {
        tableView.setEditing(editing, animated: animated)
    }

    var selectedSongs: [Song] {
        state.songs.filter { selectedSongIDs.contains($0.id) }
    }

    func clearSelection() {
        selectedSongIDs.removeAll()
        tableView.indexPathsForSelectedRows?.forEach {
            tableView.deselectRow(at: $0, animated: false)
        }
        onSelectionChanged?()
    }

    func setAdActive(_ active: Bool) {
        guard isAdActive != active else { return }
        isAdActive = active
        ads.setEnabled(active && !state.songs.isEmpty, maximumAdCount: state.songs.nativeAdSlotCount)
    }

    private func updateContent() {
        let isWaiting = state.isLoading || (!state.hasLoaded && state.errorDescription == nil)
        if isWaiting && state.songs.isEmpty { indicator.startAnimating() } else { indicator.stopAnimating() }
        messageLabel.text = state.errorDescription ?? (state.hasLoaded && state.songs.isEmpty ? emptyMessage : nil)
        messageLabel.isHidden = messageLabel.text == nil
        ads.setEnabled(isAdActive && !state.songs.isEmpty, maximumAdCount: state.songs.nativeAdSlotCount)
        updateItems()
    }

    private func updateItems() {
        let updated = state.songs.displayItems(nativeAdCount: ads.availableAdCount)
        guard items != updated else { return }
        items = updated
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row] {
        case let .song(song, rank):
            let cell = tableView.dequeueReusableCell(withIdentifier: SongTableViewCell.identifier,
                                                    for: indexPath) as! SongTableViewCell
            cell.setup(rank: rank, song: song)
            return cell
        case .nativeAd:
            return tableView.dequeueReusableCell(withIdentifier: NativeAdTableViewCell.identifier, for: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard items.indices.contains(indexPath.row), case let .nativeAd(slot) = items[indexPath.row],
              let cell = cell as? NativeAdTableViewCell else { return }
        ads.configure(cell, slot: slot)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as? NativeAdTableViewCell)?.clearAd()
    }

    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let requestedAdCount = indexPaths.compactMap { indexPath -> Int? in
            guard items.indices.contains(indexPath.row), case let .song(_, rank) = items[indexPath.row] else {
                return nil
            }
            return state.songs.nativeAdCountToRequest(prefetchingSongAt: rank)
        }.max()
        if let requestedAdCount {
            ads.requestAds(upTo: requestedAdCount)
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        items[indexPath.row].song == nil ? nil : indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let song = items[indexPath.row].song else { return }
        if tableView.isEditing {
            selectedSongIDs.insert(song.id)
            onSelectionChanged?()
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        onSelect?(song)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard tableView.isEditing, let song = items[indexPath.row].song else { return }
        selectedSongIDs.remove(song.id)
        onSelectionChanged?()
    }

}
