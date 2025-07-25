//
//  FourCutFrameModel.swift
//  MyFourCut
//
//  Created by 조영민 on 6/24/25.
//

import SwiftUI

struct FourCutFrameModel {
    private(set) var photos: [PhotoModel?] = Array(repeating: nil, count: 4)
    var selectedBackground: BackgroundModel
    
    init(selectedBackground: BackgroundModel = BackgroundModel.defaultBackgrounds[0]) {
        self.selectedBackground = selectedBackground
    }
    
    mutating func addPhoto(_ photo: PhotoModel) -> Bool {
        if let firstEmptyIndex = photos.firstIndex(where: { $0 == nil }) {
            photos[firstEmptyIndex] = photo
            return true
        }
        return false
    }
    
    mutating func removePhoto(at index: Int) {
        guard index < photos.count else { return }
        photos[index] = nil
    }
    
    mutating func setPhoto(_ photo: PhotoModel?, at index: Int) {
        guard index < photos.count else { return }
        photos[index] = photo
    }
    
    mutating func changeBackground(_ background: BackgroundModel) {
        selectedBackground = background
    }
    
    mutating func setImages(_ images: [Image?]) {
        for (index, image) in images.enumerated() {
            if index < photos.count {
                if let image = image {
                    if let uiImage = image.asUIImage() {
                        photos[index] = PhotoModel(uiImage: uiImage)
                    } else {
                        photos[index] = PhotoModel.fromImage(image)
                    }
                } else {
                    photos[index] = nil
                }
            }
        }
    }
    
    mutating func reset() {
        photos = Array(repeating: nil, count: 4)
    }
    
    var isComplete: Bool {
        return photos.allSatisfy { $0 != nil }
    }
    
    var isEmpty: Bool {
        return photos.allSatisfy { $0 == nil }
    }
    
    var filledCount: Int {
        return photos.compactMap { $0 }.count
    }
    
    var displayedImages: [Image?] {
        return photos.map { $0?.image }
    }
    
    var uiImages: [UIImage?] {
        return photos.map { $0?.originalUIImage }
    }
}
