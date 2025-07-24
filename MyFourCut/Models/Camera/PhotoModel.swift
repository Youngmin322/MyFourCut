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
        // CameraService에서 이미 방향 처리를 했으므로 그대로 사용
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
    
    static func == (lhs: PhotoModel, rhs: PhotoModel) -> Bool {
        return lhs.id == rhs.id
    }
}
