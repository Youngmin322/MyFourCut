//
//  PhotoLibraryService.swift
//  MyFourCut
//
//  Created by 조영민 on 7/14/25.
//

import Photos
import UIKit

class PhotoLibraryService {
    static let shared = PhotoLibraryService()
    
    private init() {}
    
    func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status == .authorized || status == .limited)
            }
        }
    }
    
    func fetchAssets() -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var assets: [PHAsset] = []
        
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        return assets
    }
    
    func loadImage(from asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let manager = PHImageManager.default()
            let option = PHImageRequestOptions()
            option.deliveryMode = .highQualityFormat
            
            manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: option) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    func loadImages(from assets: [PHAsset], targetSize: CGSize) async -> [UIImage] {
        var images: [UIImage] = []
        
        for asset in assets {
            if let image = await loadImage(from: asset, targetSize: targetSize) {
                images.append(image)
            }
        }
        
        return images
    }
}
