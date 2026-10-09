//
//  PersistenceManager+Rx.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 5/3/24.
//

import CoreData
import RxSwift

extension Reactive where Base == PersistenceManager {
    func fetchFavoriteSongs(brand: String) -> Single<[Song]> {
        return Single.create { single in
            do {
                let data = try self.base.fetchByBrand(brand: brand)
                let songs = data.compactMap { song -> Song? in
                    guard let str = song.brand,
                          let brand = BrandType.currentByName(name: str),
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
                                isStar: true,
                                memo: song.memo)
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

    func deleteSongs(songIDs ids: [String]) -> Single<Bool> {
        Single.create { single in
            do {
                single(.success(try self.base.deleteSongs(ids: ids)))
            } catch {
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
