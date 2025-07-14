//
//  FramePreviewViewModel.swift
//  MyFourCut
//
//  Created by 조영민 on 7/14/25.
//

import SwiftUI

@MainActor
@Observable
class FramePreviewViewModel {
    var frameImageIndices: [Int] = []
    
    func toggleImageSelection(_ index: Int) {
        if frameImageIndices.contains(index) {
            frameImageIndices.removeAll { $0 == index }
        } else if frameImageIndices.count < 4 {
            frameImageIndices.append(index)
        }
    }
    
    func isImageInFrame(_ index: Int) -> Bool {
        frameImageIndices.contains(index)
    }
    
    func getFramePosition(for index: Int) -> Int? {
        frameImageIndices.firstIndex(of: index)
    }
    
    func canProceedToNext() -> Bool {
        frameImageIndices.count >= 4
    }
    
    func getOrderedImages(from selectedImages: [Image]) -> [Image] {
        return frameImageIndices.map { selectedImages[$0] }
    }
}
