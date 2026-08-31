//
//  UITestingKaraokeSearchService.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2026/08/31.
//

#if DEBUG
import Foundation
import RxSwift

final class UITestingKaraokeSearchService: KaraokeSongSearching {
    private let songs = (1...10).map { index in
        Song(brand: .tj, no: "\(10000 + index)", title: "테스트 노래 \(index)", singer: "테스트 가수 \(index)", composer: "테스트 작곡가", lyricist: "테스트 작사가", release: "2026")
    }

    func rankSongsRequest(brand: BrandType, date: RankDateType) -> Single<[Song]> { .just(songs) }

    func searchSongsRequest(brand: BrandType, query: String, searchType: SearchType) -> Single<[Song]> {
        .just(songs.filter {
            switch searchType {
            case .title: return $0.title.localizedCaseInsensitiveContains(query)
            case .singer: return $0.singer.localizedCaseInsensitiveContains(query)
            case .popular, .release: return true
            }
        })
    }
}
#endif
