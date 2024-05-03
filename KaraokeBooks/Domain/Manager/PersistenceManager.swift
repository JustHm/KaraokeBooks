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
        let container = NSPersistentContainer(name: "Model.xcdatamodeld")
        
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
    
    func fetchData(request: NSManagedObject) -> [FavoriteSong] {
        do {
            let fetchRequest = FavoriteSong.fetchRequest()
            return try self.context.fetch(fetchRequest)
        } catch {
            //ERROR
            return []
        }
    }
    
    func addFavoriteSong(song: Song) -> Bool {
        let entity = NSEntityDescription.entity(forEntityName: "FavoriteSong", in: self.context)
        if let entity {
            let managedObject = NSManagedObject(entity: entity, insertInto: self.context)
            managedObject.setValue(song.id, forKey: "id")
            managedObject.setValue(song.brand, forKey: "brand")
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
    
    func getCurrentObject(songID id: String) -> [FavoriteSong]? {
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
    
    func deleteSong(object: NSManagedObject) -> Bool {
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
            let _ = try context.fetch(request)
            return true
        } catch {
            return false
        }
    }
}
