//
//  FavoriteMemoAndRouletteTests.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/08/31.
//

import XCTest
import CoreData
@testable import KaraokeBooks

final class FavoriteMemoAndRouletteTests: XCTestCase {
    func testRouletteDrawsEachUniqueSongBeforeStartingAnotherCycle() {
        let songs = (0..<4).map { song(number: String($0)) }
        let reactor = FavoriteRouletteReactor(songs: songs + [songs[0]])
        var state = reactor.initialState
        var drawn = Set<String>()
        for _ in songs {
            state = reactor.reduce(state: state, mutation: .draw)
            XCTAssertTrue(drawn.insert(state.song!.id).inserted)
        }
        XCTAssertEqual(drawn, Set(songs.map(\.id)))
        XCTAssertTrue(state.remaining.isEmpty)
        state = reactor.reduce(state: state, mutation: .draw)
        XCTAssertEqual(state.remaining.count, 3)
    }

    func testRouletteRefreshesMemoAndRemovesDeletedFavorites() {
        var first = song(number: "1")
        let second = song(number: "2")
        let reactor = FavoriteRouletteReactor(songs: [first, second])
        var state = reactor.initialState
        state.song = first
        state.remaining = [second]
        first.memo = "키 -2"
        state = reactor.reduce(state: state, mutation: .refresh([first, second]))
        XCTAssertEqual(state.song?.memo, "키 -2")
        XCTAssertEqual(state.remaining.map(\.id), [second.id])
        state = reactor.reduce(state: state, mutation: .refresh([second]))
        XCTAssertNil(state.song)
        state = reactor.reduce(state: state, mutation: .draw)
        XCTAssertEqual(state.song?.id, second.id)
        state = reactor.reduce(state: state, mutation: .refresh([]))
        state = reactor.reduce(state: state, mutation: .draw)
        XCTAssertNil(state.song)
        XCTAssertTrue(state.remaining.isEmpty)
    }

    func testOldStoreMigratesAndMemoPersistsWithoutMergingDuplicates() throws {
        let modelDirectory = try XCTUnwrap(Bundle(for: PersistenceManager.self).url(forResource: "SongModel", withExtension: "momd"))
        let oldModel = try XCTUnwrap(NSManagedObjectModel(contentsOf: modelDirectory.appendingPathComponent("SongModel.mom")))
        let newModel = try XCTUnwrap(NSManagedObjectModel(contentsOf: modelDirectory.appendingPathComponent("SongModel-v2.mom")))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("favorites.sqlite")
        let favorite = song(number: "14515")
        let old = try container(model: oldModel, url: url)
        for _ in 0..<2 {
            let record = NSEntityDescription.insertNewObject(forEntityName: "FavoriteSong", into: old.viewContext)
            for (key, value) in ["id": favorite.id, "brand": favorite.brand.name, "number": favorite.no,
                                 "title": favorite.title, "singer": favorite.singer,
                                 "composer": favorite.composer, "lyricist": favorite.lyricist] {
                record.setValue(value, forKey: key)
            }
        }
        try old.viewContext.save()
        try close(old)
        let migrated = try container(model: newModel, url: url)
        let persistence = PersistenceManager(container: migrated)
        XCTAssertNil(try persistence.memo(songID: favorite.id))
        XCTAssertEqual(try persistence.fetchByBrand(brand: favorite.brand.name).count, 2)
        try persistence.saveMemo("  키 -2\n후렴은 천천히  ", songID: favorite.id)
        XCTAssertTrue(try persistence.fetchByBrand(brand: favorite.brand.name).allSatisfy { $0.memo == "키 -2\n후렴은 천천히" })
        try close(migrated)
        let reopened = try container(model: newModel, url: url)
        let restored = PersistenceManager(container: reopened)
        XCTAssertEqual(try restored.memo(songID: favorite.id), "키 -2\n후렴은 천천히")
        try restored.saveMemo(" \n ", songID: favorite.id)
        XCTAssertNil(try restored.memo(songID: favorite.id))
        try restored.saveMemo("삭제할 메모", songID: favorite.id)
        try restored.deleteSongs(ids: [favorite.id])
        XCTAssertNil(try restored.memo(songID: favorite.id))
        XCTAssertThrowsError(try restored.saveMemo("없는 곡", songID: favorite.id))
        try close(reopened)
    }

    private func container(model: NSManagedObjectModel, url: URL) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "SongModel", managedObjectModel: model)
        let description = NSPersistentStoreDescription(url: url)
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        var failure: Error?
        container.loadPersistentStores { _, error in failure = error }
        if let failure { throw failure }
        return container
    }

    private func close(_ container: NSPersistentContainer) throws {
        container.viewContext.reset()
        for store in container.persistentStoreCoordinator.persistentStores {
            try container.persistentStoreCoordinator.remove(store)
        }
    }

    private func song(number: String) -> Song {
        Song(brand: .tj, no: number, title: "테스트 곡", singer: "가수", composer: "작곡", lyricist: "작사", release: "")
    }
}
