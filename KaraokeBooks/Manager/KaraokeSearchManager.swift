//
//  KaraokeSearchManager.swift
//  KaraokeBooks
//
//  Created by 안정흠 on 2023/02/08.
//

import Foundation
import Alamofire

protocol KaraokeSearchManagerProtocol {
    func searchRequest(
        brand: BrandType,
        query: String,
        searchType: SearchType,
        completionHandler: @escaping ([Song]) -> Void
    )
    func rankRequest(
        brand: BrandType,
        date: RankDateType,
        completionHandler: @escaping ([Song]) -> Void
    )
}

struct KaraokeSearchManager: KaraokeSearchManagerProtocol {
    private let searchURL = KaraokeSearchInfo()
    func searchRequest(
        brand: BrandType,
        query: String,
        searchType: SearchType,
        completionHandler: @escaping ([Song]) -> Void
    ) {
        guard let url = searchURL.searchURL(query: query, searchType: searchType) else { return }

        let param = KaraokeRequestModel(brand: brand.rawValue)
        
        AF.request(url, method: .get, parameters: param)
            .responseDecodable(of: [Song].self) { response in
                switch response.result {
                case .success(let data):
                    completionHandler(data)
                case .failure(let error):
                    print("error:" + error.localizedDescription)
                    completionHandler([])
                }
            }
            .resume()
    }
    func rankRequest(
        brand: BrandType,
        date: RankDateType,
        completionHandler: @escaping ([Song]) -> Void
    ) {
        guard let url = searchURL.rankingURL(brand: brand, date: date) else { return }
        
        AF.request(url, method: .get)
            .responseDecodable(of: [Song].self) { response in
                switch response.result {
                case .success(let data):
                    completionHandler(data)
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler([])
                }
            }
            .resume()
    }
}
