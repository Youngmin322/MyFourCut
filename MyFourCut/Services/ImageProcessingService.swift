//
//  ImageProcessingService.swift
//  MyFourCut
//
//  Created by 조영민 on 7/14/25.
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
    
    // 새로운 메서드: BackgroundModel 사용
    func renderFrameImage(
        displayedImages: [Image?],
        selectedBackground: BackgroundModel,
        selectedFilter: FilterType
    ) -> UIImage? {
        let renderer = ImageRenderer(content:
                                        ZStack {
            FrameImages(
                displayedImages: .constant(displayedImages),
                selectedBackground: selectedBackground,
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
    
    // 기존 메서드: 호환성을 위해 유지 (deprecated)
    func renderFrameImage(
        displayedImages: [Image?],
        backgroundImage: String?,
        selectedFilter: FilterType
    ) -> UIImage? {
        // 기본 배경을 찾아서 새로운 메서드 호출
        let background: BackgroundModel
        if let backgroundImage = backgroundImage,
           let foundBackground = BackgroundModel.defaultBackgrounds.first(where: { $0.imageName == backgroundImage }) {
            background = foundBackground
        } else {
            background = BackgroundModel.defaultBackgrounds[0] // 기본 배경
        }
        
        return renderFrameImage(
            displayedImages: displayedImages,
            selectedBackground: background,
            selectedFilter: selectedFilter
        )
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
