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
//    func fetchData() -> [FavoriteSong] {
//        do {
//            let fetchRequest = FavoriteSong.fetchRequest()
//            let data = try self.context.fetch(fetchRequest)
//            return data
//        } catch {
//            //ERROR
//            print("\(error.localizedDescription)")
//            return []
//        }
//    }
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
                return true
            }
            catch { throw PersistenceError.addError }
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

extension Reactive where Base == PersistenceManager {
    func fetchFavoriteSongs(brand: String) -> Single<[Song]> {
        return Single.create { single in
            do {
                let data = try self.base.fetchByBrand(brand: brand)
                let songs = data.compactMap { song -> Song? in
                    guard let brandString = song.brand,
                          let brand = BrandType(rawValue: brandString),
                          let no = song.number,
                          let title = song.title,
                          let singer = song.singer,
                          let composer = song.composer,
                          let lyricist = song.lyricist else { return nil }
                    return Song(brand: brand,
                                no: no,
                                title: title,
                                singer: singer,
                                composer: composer,
                                lyricist: lyricist,
                                release: "",
                                isStar: true)
                }
                single(.success(songs))
            }
            catch {
                single(.failure(error))
            }
            return Disposables.create()
        }
    }
    func checkExistSong(songID id: String) -> Single<Bool> {
        return Single.create { single in
            do {
                single(.success(try self.base.isExist(songID: id)))
            }
            catch {
                single(.failure(error))
            }
            return Disposables.create()
        }
    }
    
    func deleteSong(songID id: String) -> Single<Bool> {
        return Single.create { single in
            do {
                single(.success(try self.base.deleteSong(id: id)))
            }
            catch {
                single(.failure(error))
            }
            return Disposables.create()
        }
    }
    func addFavoriteSong(song: Song) -> Single<Bool> {
        return Single.create { single in
            do {
                single(.success(try self.base.addFavoriteSong(song: song)))
            }
            catch {
                single(.failure(error))
            }
            return Disposables.create()
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


enum PersistenceError: Error {
    case entityError // PersistenceManger Load Failed
    case fetchError
    case addError
}

extension PersistenceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .addError: return "노래의 데이터가 누락되어 저장하지 못했습니다."
        case .entityError: return "저장소를 찾을 수 없습니다."
        case .fetchError: return "가져오기 실패."
        }
    }
}
