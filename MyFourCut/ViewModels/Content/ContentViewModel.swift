//
//  ContentViewModel.swift
//  MyFourCut
//
//  Created by 조영민 on 6/24/25.
//

import SwiftUI

@MainActor
@Observable
class ContentViewModel {
    // Services
    private let imageProcessingService = ImageProcessingService.shared
    
    // Models
    private var frameModel = FourCutFrameModel()
    
    // Published Properties
    var selectedImages: [Image] = []
    var showingSaveAlert = false
    var displayedImages: [Image?] = []
    var currentTab: ContentTab = .frame
    var selectedFilter: FilterType = .none
    
    // Computed Properties
    var backgroundImage: String? {
        frameModel.selectedBackground.imageName
    }
    
    let backgroundImages = BackgroundModel.defaultBackgrounds.map { $0.imageName }
    
    init(initialImages: [Image?]? = nil) {
        if let images = initialImages {
            frameModel.setImages(images)
            self.displayedImages = frameModel.displayedImages
            self.selectedImages = images.compactMap { $0 }
        }
    }
    
    // MARK: - Public Methods
    
    func addSelectedImage(_ image: Image) {
        if selectedImages.count < 8 {
            selectedImages.append(image)
            updateDisplayedImages()
        }
    }
    
    func removeSelectedImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
        updateDisplayedImages()
    }
    
    func updateFrameImages(with orderedImages: [Image]) {
        var newDisplayedImages: [Image?] = []
        
        for i in 0..<4 {
            if i < orderedImages.count {
                newDisplayedImages.append(orderedImages[i])
            } else {
                newDisplayedImages.append(nil)
            }
        }
        
        displayedImages = newDisplayedImages
        frameModel.setImages(newDisplayedImages)
    }
    
    func savePhoto() {
        guard let image = imageProcessingService.renderFrameImage(
            displayedImages: displayedImages,
            backgroundImage: backgroundImage,
            selectedFilter: selectedFilter
        ) else { return }
        
        imageProcessingService.saveToPhotoAlbum(image)
        showingSaveAlert = true
    }
    
    func sharePhoto() {
        guard let image = imageProcessingService.renderFrameImage(
            displayedImages: displayedImages,
            backgroundImage: backgroundImage,
            selectedFilter: selectedFilter
        ) else { return }
        
        imageProcessingService.shareImage(image)
    }
    
    func selectBackgroundImage(_ imageName: String) {
        if let background = BackgroundModel.defaultBackgrounds.first(where: { $0.imageName == imageName }) {
            frameModel.changeBackground(background)
        }
    }
    
    func removeImage(at index: Int) {
        frameModel.removePhoto(at: index)
        self.displayedImages = frameModel.displayedImages
    }
    
    // MARK: - Private Methods
    
    private func updateDisplayedImages() {
        let imagesToDisplay = Array(selectedImages.prefix(4))
        var images: [Image?] = imagesToDisplay
        
        while images.count < 4 {
            images.append(nil)
        }
        
        displayedImages = images
        frameModel.setImages(images)
    }
}
