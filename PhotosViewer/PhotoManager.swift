//
//  PhotoManager.swift
//  PhotosViewer
//
//  Created by Nathan Taylor on 6/17/19.
//  Copyright © 2019 Nathan Taylor. All rights reserved.
//

import Foundation
import UIKit

class PhotoManager : NSObject, URLSessionTaskDelegate {
    // MARK: - Public
    var photos: [Photo] {
        get {
            var result: [Photo] = []
            os_unfair_lock_lock(&_lock)
            result = _photos
            os_unfair_lock_unlock(&_lock)
            return result
        }
        set {
            os_unfair_lock_lock(&_lock)
            _photos = newValue
            os_unfair_lock_unlock(&_lock)
        }
    }
    
    var count: Int {
        get {
            var result: Int = 0
            os_unfair_lock_lock(&_lock)
            result = _count
            os_unfair_lock_unlock(&_lock)
            return result
        }
        set {
            os_unfair_lock_lock(&_lock)
            _count = newValue
            os_unfair_lock_unlock(&_lock)
        }
    }

    init(configuration: URLSessionConfiguration) {
        self.session = URLSession(configuration: configuration)
    }
    
    func loadPhotos(completion: @escaping ([Photo]?, Error?) -> Void) {
        weak var weakSelf: PhotoManager? = self
        let task = session.dataTask(with: photosURL) { data, response, error in
            guard let blockSelf = weakSelf, error == nil, let d = data  else {
                completion(nil, error)
                return
            }
            
            guard let result = try? JSONDecoder().decode(GetPhotosResponse.self, from: d) else {
                completion(nil, error)
                return
            }
            
            blockSelf.photos = result.photos
            blockSelf.count = result.photos.count
            completion(result.photos, nil)
        }
        task.resume()
    }
    
    func loadImage(for photo: Photo, size: Photo.ImageSize, completion: @escaping (UIImage?) -> Void) -> URLSessionTask? {
        weak var weakSelf: PhotoManager? = self
        
        guard let url = photo.imageURL(size: size) else {
            completion(nil)
            return nil
        }
        
        
        let task = imageSession.dataTask(with: url) { data, response, error in
            var image: UIImage? = nil
            if let d = data {
                image = UIImage(data: d)
            }
            completion(image)
        }
        
        task.resume()
        return task
    }
    
    // MARK: - Private
    private let photosURL = URL(string: "https://kqlpe1bymk.execute-api.us-west-2.amazonaws.com/Prod/users/self/media/recent")!
    private let session: URLSession
    private let imageSession = URLSession(configuration: .default)

    private var _lock = os_unfair_lock_s()
    private var _photos: [Photo] = []
    private var _count = 0
    
    class Photo : Codable {
        enum ImageSize : Int {
            case thumbnail = 150
            case small = 320
            case standard = 640
        }
        
        class Likes : Codable {
            enum CodingKeys: String, CodingKey {
                case count
            }
            
            let count: Int
        }
        
        class User : Codable {
            enum CodingKeys: String, CodingKey {
                case id
                case username
                case name = "full_name"
                case urlString = "profile_picture"
            }
            
            let id: String
            let username: String
            let name: String
            let urlString: String
            
            var profileURL: URL? {
                return URL(string: urlString)
            }
        }
        
        
        class ImageSet : Codable {
            class ImageRef : Codable {
                enum CodingKeys: String, CodingKey {
                    case height
                    case width
                    case urlString = "url"
                }
                
                let height: Int
                let width: Int
                let urlString: String
                
                var imageURL: URL? {
                    return URL(string: urlString)
                }
            }
            
            enum CodingKeys: String, CodingKey {
                case thumb = "thumbnail"
                case low = "low_resolution"
                case standard = "standard_resolution"
            }
            
            let thumb: ImageRef
            let low: ImageRef
            let standard: ImageRef
        }
        
        enum CodingKeys: String, CodingKey {
            case likes
            case id = "media_id"
            case user
            case liked = "user_has_liked"
            case tags
            case images
        }
        
        let likes: Likes
        let id: String
        let user: User
        let liked: Bool
        let tags: [String]
        let images: ImageSet
        
        func imageURL(size: ImageSize) -> URL? {
            switch (size) {
            case .thumbnail:
                return images.thumb.imageURL
            case .small:
                return images.low.imageURL
            case .standard:
                return images.standard.imageURL
            }
        }
    }
    
    class GetPhotosResponse : Codable {
        enum CodingKeys: String, CodingKey {
            case photos = "data"
        }
        
        let photos: [Photo]
        
    }

}

