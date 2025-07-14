//
//  PhotoSelectionViewModel.swift
//  MyFourCut
//
//  Created by 조영민 on 7/14/25.
//

import SwiftUI
import Photos

@MainActor
@Observable
class PhotoSelectionViewModel {
    // Services
    private let photoLibraryService = PhotoLibraryService.shared
    
    // Published Properties
    var galleryImages: [PHAsset] = []
    var selectedAssets: [PHAsset] = []
    var isLoading = false
    var hasPermission = false
    
    // MARK: - Public Methods
    
    func requestPermissionAndLoadImages() async {
        isLoading = true
        hasPermission = await photoLibraryService.requestPermission()
        
        if hasPermission {
            galleryImages = photoLibraryService.fetchAssets()
        }
        
        isLoading = false
    }
    
    func toggleAssetSelection(_ asset: PHAsset) {
        if selectedAssets.contains(asset) {
            selectedAssets.removeAll { $0 == asset }
        } else if selectedAssets.count < 8 {
            selectedAssets.append(asset)
        }
    }
    
    func removeAsset(at index: Int) {
        guard index < selectedAssets.count else { return }
        selectedAssets.remove(at: index)
    }
    
    func convertSelectedAssetsToImages() async -> [Image] {
        let images = await photoLibraryService.loadImages(from: selectedAssets, targetSize: CGSize(width: 300, height: 300))
        return images.map { Image(uiImage: $0) }
    }
    
    func isAssetSelected(_ asset: PHAsset) -> Bool {
        selectedAssets.contains(asset)
    }
    
    func getSelectionIndex(for asset: PHAsset) -> Int? {
        selectedAssets.firstIndex(of: asset)
    }
}
