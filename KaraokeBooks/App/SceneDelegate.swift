//
//  SceneDelegate.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = UINavigationController(rootViewController: HomeViewController())
        window?.backgroundColor = .customBackground
        window?.tintColor = .systemRed
        window?.makeKeyAndVisible()
        migrationToCoreData()
    }
    
    func migrationToCoreData() {
        //데이터 이전 작업 UserDefaults -> CoreData
        enum Key: String {
            case kyFavorite
            case tjFavorite
        }
        let tj = Key.tjFavorite
        let ky = Key.kyFavorite
        var songs: [Song] = []
        if let data = UserDefaults.standard.data(forKey: tj.rawValue) {
            songs.append(contentsOf: (try? PropertyListDecoder().decode([Song].self, from: data)) ?? [])
        }
        if let data = UserDefaults.standard.data(forKey: ky.rawValue) {
            songs.append(contentsOf: (try? PropertyListDecoder().decode([Song].self, from: data)) ?? [])
        }
        
        for song in songs {
            if !PersistenceManager.shared.isExist(songID: song.id) {
                let result = PersistenceManager.shared.addFavoriteSong(song: song)
                if !result {
                    print("Failed Migration: \(song.id), \(song.title)")
                }
            }
        }
    }
}

