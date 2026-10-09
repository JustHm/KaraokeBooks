//
//  PersistenceManager.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 5/3/24.
//

import CoreData
import RxSwift

enum PersistenceEvent {
    case deleted(Bool)
}
final class PersistenceManager: ReactiveCompatible {
    static var shared: PersistenceManager = PersistenceManager()
    let event = PublishSubject<PersistenceEvent>()
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SongModel")
        
        container.persistentStoreDescriptions.forEach {
            $0.shouldMigrateStoreAutomatically = true
            $0.shouldInferMappingModelAutomatically = true
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        return container
    }()
    init(container: NSPersistentContainer? = nil) {
        if let container { persistentContainer = container }
    }

    var context: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }

    func memo(songID: String) throws -> String? {
        let request: NSFetchRequest<FavoriteSong> = FavoriteSong.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", songID)
        return try context.fetch(request).compactMap { $0.memo }.first
    }

    func saveMemo(_ memo: String, songID: String) throws {
        let request: NSFetchRequest<FavoriteSong> = FavoriteSong.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", songID)
        let songs = try context.fetch(request)
        guard !songs.isEmpty else { throw PersistenceError.fetchError }
        let text = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        let previous = songs.map { $0.memo }
        songs.forEach { $0.memo = text.isEmpty ? nil : text }
        do {
            try context.save()
            event.onNext(.deleted(true))
        } catch {
            zip(songs, previous).forEach { $0.0.memo = $0.1 }
            throw error
        }
    }

    @discardableResult
    func addFavoriteSong(song: Song) throws -> Bool {
        let entity = NSEntityDescription.entity(forEntityName: "FavoriteSong", in: self.context)
        if let entity {
            let managedObject = NSManagedObject(entity: entity, insertInto: self.context)
            managedObject.setValue(song.id, forKey: "id")
            managedObject.setValue(song.brand.name, forKey: "brand")
            managedObject.setValue(song.title, forKey: "title")
            managedObject.setValue(song.no, forKey: "number")
            managedObject.setValue(song.singer, forKey: "singer")
            managedObject.setValue(song.composer, forKey: "composer")
            managedObject.setValue(song.lyricist, forKey: "lyricist")
            
            do {
                try self.context.save()
                event.onNext(.deleted(true))
                return true
            }
            catch {
                event.onNext(.deleted(false))
                throw PersistenceError.addError
            }
        }
        else {
            throw PersistenceError.entityError
        }
    }
    
    func fetchByBrand(brand: String) throws -> [FavoriteSong] {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<FavoriteSong> = FavoriteSong.fetchRequest()
        request.predicate = NSPredicate(format: "brand == %@", brand)
        do {
            let song = try context.fetch(request)
            return song
        } catch {
            throw PersistenceError.fetchError
        }
    }
    
    @discardableResult
    func deleteSong(id: String) throws -> Bool {
        let data = getCurrentObject(songID: id)
        guard !data.isEmpty else { return false }
        
        let object = data[0] as NSManagedObject
        self.context.delete(object)
        do {
            try self.context.save()
            event.onNext(.deleted(true))
            return true
        } catch {
            event.onNext(.deleted(false))
            throw PersistenceError.fetchError
        }
    }

    @discardableResult
    func deleteSongs(ids: [String]) throws -> Bool {
        guard !ids.isEmpty else { return false }

        let request: NSFetchRequest<FavoriteSong> = FavoriteSong.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", ids)

        do {
            let songs = try context.fetch(request)
            guard !songs.isEmpty else { return false }
            songs.forEach(context.delete)
            try context.save()
            event.onNext(.deleted(true))
            return true
        } catch {
            event.onNext(.deleted(false))
            throw PersistenceError.fetchError
        }
    }
    
    // 애창곡으로 되어 있는지만 확인하기 위한 용도
    func isExist(songID id: String) throws -> Bool {
        let request: NSFetchRequest<FavoriteSong> = FavoriteSong.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        do {
            let data = try self.context.fetch(request)
            if data.isEmpty { return false }
            return true
        } catch {
            throw PersistenceError.fetchError
        }
    }
}

extension PersistenceManager {
    private func getCurrentObject(songID id: String) -> [FavoriteSong] {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<FavoriteSong> = FavoriteSong.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        do {
            let song = try context.fetch(request)
            return song
        } catch {
            return []
        }
    }
}
