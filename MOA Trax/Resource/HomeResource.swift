//
//  HomeResource.swift
//  geolocate
//
//  Created by Appentus Technologies on 22/09/21.
//

import Foundation

struct HomeResource {
    func getMapList(completion: @escaping (MapListResponse?, String?) -> Void) {
        
        let mapListRequest = HURequest.init(withUrl: HomeEndPoints.mapList.url, forHttpMethod: .get, requestBody: nil)
        HttpUtility.shared.request(huRequest: mapListRequest, resultType: MapListResponse.self) { response in
            switch response {
            case .success(let result):
                completion(result, nil)
            case .failure(let error):
                completion(nil, error.reason)
            }
        }
    }
}
