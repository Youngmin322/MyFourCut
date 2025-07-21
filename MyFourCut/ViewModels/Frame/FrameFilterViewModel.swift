//
//  FrameFilterViewModel.swift
//  MyFourCut
//
//  Created by 조영민 on 7/14/25.
//

import SwiftUI

@MainActor
@Observable
class FrameFilterViewModel {
    // Services
    private let imageProcessingService = ImageProcessingService.shared
    private let hapticService = HapticService.shared
    
    // Published Properties
    var currentTab: ContentTab = .frame
    var selectedFilter: FilterType = .none
    var showingSaveAlert = false
    
    // MARK: - Public Methods
    
    func selectTab(_ tab: ContentTab) {
        hapticService.selection()
        currentTab = tab
    }
    
    func selectFilter(_ filter: FilterType) {
        hapticService.impact(.light)
        selectedFilter = filter
    }
    
    func savePhoto(displayedImages: [Image?], selectedBackground: BackgroundModel) {
        guard let image = imageProcessingService.renderFrameImage(
            displayedImages: displayedImages,
            selectedBackground: selectedBackground,
            selectedFilter: selectedFilter
        ) else { return }
        
        imageProcessingService.saveToPhotoAlbum(image)
        showingSaveAlert = true
        hapticService.notification(.success)
    }
    
    func sharePhoto(displayedImages: [Image?], selectedBackground: BackgroundModel) {
        guard let image = imageProcessingService.renderFrameImage(
            displayedImages: displayedImages,
            selectedBackground: selectedBackground,
            selectedFilter: selectedFilter
        ) else { return }
        
        imageProcessingService.shareImage(image)
        hapticService.impact(.medium)
    }
    
    func savePhoto(displayedImages: [Image?], backgroundImage: String?) {
        guard let image = imageProcessingService.renderFrameImage(
            displayedImages: displayedImages,
            backgroundImage: backgroundImage,
            selectedFilter: selectedFilter
        ) else { return }
        
        imageProcessingService.saveToPhotoAlbum(image)
        showingSaveAlert = true
        hapticService.notification(.success)
    }
    
    func sharePhoto(displayedImages: [Image?], backgroundImage: String?) {
        guard let image = imageProcessingService.renderFrameImage(
            displayedImages: displayedImages,
            backgroundImage: backgroundImage,
            selectedFilter: selectedFilter
        ) else { return }
        
        imageProcessingService.shareImage(image)
        hapticService.impact(.medium)
    }
}
