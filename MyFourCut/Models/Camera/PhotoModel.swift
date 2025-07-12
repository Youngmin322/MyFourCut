//
//  PhotoModel.swift
//  MyFourCut
//
//  Created by 조영민 on 6/24/25.
//

import SwiftUI

struct PhotoModel {
    let id = UUID()
    let image: Image
    let originalUIImage: UIImage?
    
    init(uiImage: UIImage) {
        self.originalUIImage = uiImage
        self.image = Image(uiImage: uiImage)
    }
    
    static func fromImage(_ image: Image) -> PhotoModel {
        return PhotoModel(image: image, originalUIImage: image.asUIImage())
    }
    
    private init(image: Image, originalUIImage: UIImage?) {
        self.image = image
        self.originalUIImage = originalUIImage
    }
}

extension Image {
    func asUIImage() -> UIImage? {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let uiImage = child.value as? UIImage {
                return uiImage
            }
        }
        return nil
    }
}
