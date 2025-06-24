//
//  FrameImagesViewModel.swift
//  MyFourCut
//
//  Created by 조영민 on 6/24/25.
//

import SwiftUI

@MainActor
@Observable
class FrameImagesViewModel {
    var displayedImages: [Image?]
    var backgroundImage: String?
    var showCloseButton: Bool
    
    init(displayedImages: [Image?], backgroundImage: String? = nil, showCloseButton: Bool = true) {
        self.displayedImages = displayedImages
        self.backgroundImage = backgroundImage
        self.showCloseButton = showCloseButton
    }
    
    func removeImage(at index: Int) {
        guard index < displayedImages.count else { return }
        displayedImages[index] = nil
    }
}
