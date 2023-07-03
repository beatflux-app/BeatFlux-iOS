//
//  ImageLoader.swift
//  BeatFlux
//
//  Created by Ari Reitman on 6/21/23.
//

import Foundation
import UIKit

class CachedImages {
    static var imageCache = NSCache<NSString, UIImage>()
}

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var urlString: String

    init(urlString: String) {
        self.urlString = urlString
    }
    
    func load() {
        // Check if image is already in cache
        if let cachedImage = CachedImages.imageCache.object(forKey: urlString as NSString) {
            self.image = cachedImage
            return
        }

        // If image is not in cache, load it
        guard let url = URL(string: urlString) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    CachedImages.imageCache.setObject(image, forKey: self.urlString as NSString)
                    self.image = image
                }
            }
        }.resume()
    }
}
