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
    private var frameModel: FourCutFrameModel
    
    var displayedImages: [Image?] {
        get { frameModel.displayedImages }
        set { frameModel.setImages(newValue) }
    }
    
    var backgroundImage: String? {
        frameModel.selectedBackground.imageName
    }
    
    var showCloseButton: Bool
    
    init(displayedImages: [Image?], backgroundImage: String? = nil, showCloseButton: Bool = true) {
        self.frameModel = FourCutFrameModel()
        self.showCloseButton = showCloseButton
        
        frameModel.setImages(displayedImages)
        
        if let bgName = backgroundImage {
            frameModel.changeBackgroundByName(bgName)
        }
    }
    
    func removeImage(at index: Int) {
        frameModel.removePhoto(at: index)
    }
}
