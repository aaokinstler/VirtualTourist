//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Anton Kinstler on 03.08.2021.
//

import Foundation
import CoreData
import MapKit

class FlickrClient {
    
    static let apiKey = "b0b29f8adae1108d40c5ae61f951f39b"
    
    enum Endpionts {
        static let photoBase = "https://live.staticflickr.com/"
        static let base = "https://www.flickr.com/services/rest/"
        static let apiKeyParam = "&api_key=\(FlickrClient.apiKey)"
        static let formatParam = "&format=json&nojsoncallback=1"
        
        
        case getNearbyPhotosInfo(lat: Double, lon: Double)
        case getMiniPhotoURL(photoId: String, serverId: String, secret: String)
        
        var stringValue: String {
            switch self {
            case .getNearbyPhotosInfo(lat: let lat, lon: let lon): return Endpionts.base + "?method=flickr.photos.search" + Endpionts.apiKeyParam + "&lat=\(lat)&lon=\(lon)" + Endpionts.formatParam
                
            case .getMiniPhotoURL(photoId: let photoId, serverId: let serverId, secret: let secret): return Endpionts.photoBase + "\(serverId)/\(photoId)_\(secret)_q.jpg"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func dataTask(url: URL, completion: @escaping(Data?, String?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(nil, error?.localizedDescription)
                return
            }
            completion(data, nil)
        }
        task.resume()
    }
    
    class func taskForGetRequest<ResponseType: Decodable>(url: URL, responceType: ResponseType.Type, completion: @escaping(ResponseType?, String?) -> Void) {
        dataTask(url: url) { data, error in
            guard let data = data else {
                completion(nil, error)
                return
            }
            let decoder = JSONDecoder()
            
            do {
                let responseObject = try decoder.decode(responceType, from: data)
                completion(responseObject, nil)
            } catch {
                completion(nil, error.localizedDescription)
            }
        }
    }
    
    class func getURLsForCoordinates(location: Location, completion: @escaping ([String]?, String?)-> Void) {
        let url = Endpionts.getNearbyPhotosInfo(lat: location.latitude, lon: location.longitude).url
        
        taskForGetRequest(url: url, responceType: FlickrSearchResponce.self) { data, error in
            guard let data = data else {
                completion(nil, error)
                return
            }
            
            var urlArray:[String] = []
            data.photos.photo.forEach() { photo in
                
                urlArray.append(Endpionts.getMiniPhotoURL(photoId: photo.id, serverId: photo.server, secret: photo.secret).stringValue) 
            }
            completion(urlArray, nil)
        }
    }
    
    class func downloadImage(url: URL, photoID: NSManagedObjectID, completion: @escaping (Data?, NSManagedObjectID, String?) -> Void) {
        dataTask(url: url) { data, error in
            guard let data = data else {
                completion(nil, photoID, error)
                return
            }
            
            completion(data, photoID, nil)
        }
    }
}
