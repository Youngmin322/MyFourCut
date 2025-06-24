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
        return PhotoModel(image: image, originalUIImage: nil)
    }
    
    private init(image: Image, originalUIImage: UIImage?) {
        self.image = image
        self.originalUIImage = originalUIImage
    }
}

extension Image {
    func asUIImage() -> UIImage? {
        // SwiftUI Image를 UIImage로 변환하는 것은 복잡함
        // 실제 구현에서는 원본 UIImage를 직접 전달하는 것이 좋음
        return nil
    }
}
