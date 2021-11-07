//
//  FliclrSearchResponce.swift
//  VirtualTourist
//
//  Created by Anton Kinstler on 08.08.2021.
//

import Foundation

struct FlickrSearchResponce : Decodable {
    let photos: Photos
    let stat: String
}

struct Photos : Decodable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: Int
    let photo: [PhotoInfo]
}

struct PhotoInfo : Decodable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
}
