//
//  UserDefaultsManager.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/11.
//

import Foundation

struct UserDefaultsManager {
    enum Key: String {
        case kyFavorite
        case tjFavorite
    }
    func getFavoriteSong(brand: BrandType) -> [Song] {
        let key = getKeytoBrand(brand: brand)
        guard let data = UserDefaults.standard.data(forKey: key.rawValue) else { return [] }
        return (try? PropertyListDecoder().decode([Song].self, from: data)) ?? []
    }
    
    func addFavoriteSong(_ newSong: Song) {
        var data = getFavoriteSong(brand: newSong.brand)
        let key = getKeytoBrand(brand: newSong.brand)
        data.insert(newSong, at: 0)
        UserDefaults.standard.set(try? PropertyListEncoder().encode(data), forKey: key.rawValue)
    }
    
    func deleteFavoriteSong(_ song: Song) {
        var data = getFavoriteSong(brand: song.brand)
        let key = getKeytoBrand(brand: song.brand)
        guard let index = data.firstIndex(where: { current in
            if current.no == song.no,
               current.brand == song.brand {
                return true
            } else {
                return false
            }
        }) else { return }
        data.remove(at: index)
        UserDefaults.standard.set(try? PropertyListEncoder().encode(data), forKey: key.rawValue)
    }
    func isFavoriteSong(_ song: Song) -> Bool {
        let data = getFavoriteSong(brand: song.brand)
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
    
    private func getKeytoBrand(brand: BrandType) -> Key {
        switch brand {
        case .tj:
            return Key.tjFavorite
        case .kumyoung:
            return Key.kyFavorite
        }
    }
}
