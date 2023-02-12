//
//  UserDefaultsManager.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/11.
//

import Foundation

protocol UserDefaultsManagerProtocol {
    func getFavoriteSong() -> [Song]
    func addFavoriteSong(_ newSong: Song)
    func deleteFavoriteSong(_ song: Song)
    func isFavoriteSong(_ song: Song) -> Bool
}

struct UserDefaultsManager: UserDefaultsManagerProtocol {
    enum Key: String {
        case favorite
        var key: String {
            self.rawValue
        }
    }
    func getFavoriteSong() -> [Song] {
        guard let data = UserDefaults.standard.data(forKey: Key.favorite.key) else { return [] }
        return (try? PropertyListDecoder().decode([Song].self, from: data)) ?? []
    }
    
    func addFavoriteSong(_ newSong: Song) {
        var data = getFavoriteSong()
        data.insert(newSong, at: 0)
        UserDefaults.standard.set(try? PropertyListEncoder().encode(data), forKey: Key.favorite.rawValue)
    }
    
    func deleteFavoriteSong(_ song: Song) {
        var data = getFavoriteSong()
        guard let index = data.firstIndex(where: { current in
            if current.no == song.no,
               current.brand == song.brand {
                return true
            } else {
                return false
            }
        }) else { return }
        data.remove(at: index)
        UserDefaults.standard.set(try? PropertyListEncoder().encode(data), forKey: Key.favorite.rawValue)
    }
    func isFavoriteSong(_ song: Song) -> Bool {
        let data = getFavoriteSong()
        guard let _ = data.firstIndex(where: { current in
            if current.no == song.no,
               current.brand == song.brand {
                return true
            } else {
                return false
            }
        }) else { return false }
        return true
    }
}
