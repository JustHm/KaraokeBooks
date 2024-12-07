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
        let reactor = HomeReactor()
        let vc = HomeViewController(reactor: reactor)
        window?.rootViewController = UINavigationController(rootViewController: vc)
        window?.backgroundColor = .customBackground
        window?.tintColor = .systemRed
        window?.makeKeyAndVisible()
        migrationToCoreData()
    }
    
    func migrationToCoreData() {
        //데이터 이전 작업 UserDefaults -> CoreData
        var songs: [Song] = []
        if let data = UserDefaults.standard.data(forKey: UserDefaultsManager.Key.tjFavorite.rawValue) {
            songs.append(contentsOf: (try? PropertyListDecoder().decode([Song].self, from: data)) ?? [])
        }
        if let data = UserDefaults.standard.data(forKey: UserDefaultsManager.Key.kyFavorite.rawValue) {
            songs.append(contentsOf: (try? PropertyListDecoder().decode([Song].self, from: data)) ?? [])
        }
        do {
            for song in songs {
                if try !PersistenceManager.shared.isExist(songID: song.id) {
                    let result = try PersistenceManager.shared.addFavoriteSong(song: song)
                    if !result {
                        print("Failed Migration: \(song.id), \(song.title)")
                    }
                }
            }
        } catch { print("Migration Error: \(error.localizedDescription)")}
    }
}

