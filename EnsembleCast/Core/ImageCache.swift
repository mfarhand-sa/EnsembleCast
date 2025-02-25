//
//  ImageCache.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-24.
//

import Foundation
import UIKit
// MARK: - Image Cache
class ImageCache {
    static let shared = NSCache<NSString, UIImage>()

    func getImage(forKey key: String) -> UIImage? {
        return ImageCache.shared.object(forKey: key as NSString)
    }

    func setImage(_ image: UIImage, forKey key: String) {
        ImageCache.shared.setObject(image, forKey: key as NSString)
    }
}
