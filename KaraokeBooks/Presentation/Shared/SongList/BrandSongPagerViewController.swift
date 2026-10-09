//
//  BrandSongPagerViewController.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/09/05.
//

import UIKit
import SnapKit
import RxSwift

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
