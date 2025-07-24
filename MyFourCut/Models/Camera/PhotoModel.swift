//
//  PhotoModel.swift
//  MyFourCut
//
//  Created by 조영민 on 6/24/25.
//

import SwiftUI

struct PhotoModel: Identifiable, Equatable {
    let id = UUID()
    let image: Image
    let originalUIImage: UIImage?
    
    init(uiImage: UIImage) {
        // UIImage 방향을 올바르게 처리
        let correctedUIImage = PhotoModel.correctImageOrientation(uiImage)
        self.originalUIImage = correctedUIImage
        self.image = Image(uiImage: correctedUIImage)
    }
    
    static func fromImage(_ image: Image) -> PhotoModel {
        return PhotoModel(image: image, originalUIImage: image.asUIImage())
    }
    
    private init(image: Image, originalUIImage: UIImage?) {
        self.image = image
        self.originalUIImage = originalUIImage
    }
    
    private static func correctImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        // 이미지를 올바른 방향으로 회전
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let correctedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return correctedImage ?? image
    }
    
    static func == (lhs: PhotoModel, rhs: PhotoModel) -> Bool {
        return lhs.id == rhs.id
    }
}
