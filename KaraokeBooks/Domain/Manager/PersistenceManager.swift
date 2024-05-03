//
//  PersistenceManager.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 5/3/24.
//

import CoreData

class PersistenceManager {
    static var shared: PersistenceManager = PersistenceManager()
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SongModel")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        return container
    }()
    var context: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }
    
    func fetchData() -> [FavoriteSong] {
        do {
            let fetchRequest = FavoriteSong.fetchRequest()
            let data = try self.context.fetch(fetchRequest)
            return data
        } catch {
            //ERROR
            print("\(error.localizedDescription)")
            return []
        }
    }
    @discardableResult
    func addFavoriteSong(song: Song) -> Bool {
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
                return true
            } catch {
                //ERROR
                return false
            }
        }
        else {
            //ERROR
            return false
        }
    }
    
    func getCurrentObject(songID id: String) -> [FavoriteSong] {
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
    func fetchByBrand(brand: String) -> [FavoriteSong] {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<FavoriteSong> = FavoriteSong.fetchRequest()
        request.predicate = NSPredicate(format: "brand == %@", brand)
        do {
            let song = try context.fetch(request)
            return song
        } catch {
            return []
        }
    }
    
    @discardableResult
    func deleteSong(id: String) -> Bool {
        let data = getCurrentObject(songID: id)
        guard !data.isEmpty else { return false }
        
        let object = data[0] as NSManagedObject
        
        self.context.delete(object)
        do {
            try self.context.save()
            return true
        } catch {
            //ERROR
            return false
        }
    }
    
    // 애창곡으로 되어 있는지만 확인하기 위한 용도
    func isExist(songID id: String) -> Bool {
        let request: NSFetchRequest<FavoriteSong> = FavoriteSong.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        do {
            let data = try self.context.fetch(request)
            if data.isEmpty { return false }
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}
