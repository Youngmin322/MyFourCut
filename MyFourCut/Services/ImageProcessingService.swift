//
//  ImageProcessingService.swift
//  MyFourCut
//
//  Created by 조영민 on 7/14/25.
//

//
//  ImageProcessingService.swift
//  MyFourCut
//

import SwiftUI
import UIKit

@MainActor
class ImageProcessingService {
    static let shared = ImageProcessingService()
    
    private init() {}
    
    func saveToPhotoAlbum(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    func shareImage(_ image: UIImage) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        rootVC.present(activityVC, animated: true)
    }
    
    func renderFrameImage(
        displayedImages: [Image?],
        backgroundImage: String?,
        selectedFilter: FilterType
    ) -> UIImage? {
        let renderer = ImageRenderer(content:
            ZStack {
                FrameImages(
                    displayedImages: .constant(displayedImages),
                    backgroundImage: backgroundImage,
                    showCloseButton: false
                )
                .frame(width: 300, height: 500)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 1)
                )
                
                if selectedFilter != .none {
                    Rectangle()
                        .fill(selectedFilter.color.opacity(0.3))
                        .frame(width: 300, height: 500)
                        .blendMode(getBlendMode(for: selectedFilter))
                }
            }
        )
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
    
    private func getBlendMode(for filter: FilterType) -> BlendMode {
        switch filter {
        case .none: return .normal
        case .blackWhite: return .luminosity
        case .sepia, .vintage: return .multiply
        case .cool, .warm: return .colorBurn
        }
    }
}
