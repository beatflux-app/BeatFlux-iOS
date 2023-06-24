//
//  ImageLoader.swift
//  BeatFlux
//
//  Created by Ari Reitman on 6/21/23.
//

import Foundation
import UIKit

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var urlString: String
    private var imageCache = NSCache<AnyObject, AnyObject>()

    init(urlString: String) {
        self.urlString = urlString
    }
    
    func load() {
        // Check if image is already in cache
        if let cachedImage = self.imageCache.object(forKey: urlString as NSString) as? UIImage {
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
                    self.imageCache.setObject(image, forKey: self.urlString as NSString)
                    self.image = image
                }
            }
        }.resume()
    }
}
