//
//  CustomFrameService.swift
//  MyFourCut
//
//  Created by 조영민 on 7/16/25.
//

import SwiftUI
import Photos

@MainActor
class CustomFrameService: ObservableObject {
    static let shared = CustomFrameService()
    
    @Published var customFrames: [BackgroundModel] = []
    
    private init() {
        loadCustomFrames()
    }
    
    func addCustomFrame(from asset: PHAsset, displayName: String) async {
        guard let image = await PhotoLibraryService.shared.loadImage(
            from: asset,
            targetSize: CGSize(width: 300, height: 500)
        ) else { return }
        
        let newFrame = BackgroundModel(
            id: UUID().uuidString,
            customImage: image,
            displayName: displayName
        )
        
        customFrames.append(newFrame)
        saveCustomFrames()
    }
    
    private func loadCustomFrames() {
        
    }
    
    private func saveCustomFrames() {
        
    }
}
