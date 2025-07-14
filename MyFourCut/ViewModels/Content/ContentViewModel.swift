//
//  ContentViewModel.swift
//  MyFourCut
//
//  Created by 조영민 on 6/24/25.
//

import SwiftUI
import PhotosUI

enum ContentTab {
    case frame
    case filter
}

@MainActor
@Observable
class ContentViewModel {
    private var frameModel = FourCutFrameModel()
    var selectedPhotos: [PhotosPickerItem] = []
    var selectedImages: [Image] = []  // 최대 8장
    var showingSaveAlert = false
    var displayedImages: [Image?] = []
    var currentTab: ContentTab = .frame
    var selectedFilter: FilterType = .none
    
    var backgroundImage: String? {
        frameModel.selectedBackground.imageName
    }
    
    let backgroundImages = BackgroundModel.defaultBackgrounds.map { $0.imageName }
    
    init(initialImages: [Image?]? = nil) {
        if let images = initialImages {
            frameModel.setInitialImages(images)
            self.displayedImages = frameModel.displayedImages
            self.selectedImages = images.compactMap { $0 }
        }
    }
    
    // 선택된 이미지 추가
    func addSelectedImage(_ image: Image) {
        if selectedImages.count < 8 {
            selectedImages.append(image)
            updateDisplayedImages()
        }
    }
    
    // 선택된 이미지 제거
    func removeSelectedImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
        updateDisplayedImages()
    }
    
    // 표시할 이미지 업데이트 (처음 4장만)
    private func updateDisplayedImages() {
        let imagesToDisplay = Array(selectedImages.prefix(4))
        var images: [Image?] = imagesToDisplay
        
        // 4장 미만이면 nil로 채우기
        while images.count < 4 {
            images.append(nil)
        }
        
        displayedImages = images
        frameModel.setImages(images)
    }
    
    // FramePreviewView에서 선택한 이미지 순서를 업데이트하는 메서드
    func updateFrameImages(with orderedImages: [Image]) {
        // 프레임에 표시될 이미지들을 순서대로 설정
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
    
    // 프레임에서 특정 위치 이미지 변경
    func swapImage(from: Int, to: Int) {
        guard from < selectedImages.count && to < 4 else { return }
        
        // 현재 표시된 이미지 가져오기
        var currentDisplayed = Array(selectedImages.prefix(4))
        
        // from이 현재 표시된 이미지 내에 있는 경우
        if from < 4 && to < currentDisplayed.count {
            currentDisplayed.swapAt(from, to)
        } else if from >= 4 {
            // from이 표시되지 않은 이미지인 경우
            let imageToSwap = selectedImages[from]
            if to < currentDisplayed.count {
                selectedImages[from] = currentDisplayed[to]
                currentDisplayed[to] = imageToSwap
            }
        }
        
        // 선택된 이미지 업데이트
        for (index, image) in currentDisplayed.enumerated() {
            if index < selectedImages.count {
                selectedImages[index] = image
            }
        }
        
        updateDisplayedImages()
    }
    
    func loadTransferable() async {
        var newImages: [Image] = []
        
        for photoItem in selectedPhotos {
            do {
                if let imageData = try await photoItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: imageData) {
                    let image = Image(uiImage: uiImage)
                    newImages.append(image)
                }
            } catch {
                print("이미지 로드 실패: \(error)")
            }
        }
        
        // 새 이미지들 추가 (8장 제한)
        for image in newImages {
            if selectedImages.count < 8 {
                selectedImages.append(image)
            }
        }
        
        selectedPhotos.removeAll()
        updateDisplayedImages()
    }
    
    func savePhoto() {
        let renderer = ImageRenderer(content:
            ZStack {
                FrameImages(displayedImages: .constant(displayedImages),
                           backgroundImage: backgroundImage,
                           showCloseButton: false)
                .frame(width: 300, height: 500)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 1)
                )
                
                // 필터 적용
                if selectedFilter != .none {
                    Rectangle()
                        .fill(selectedFilter.color.opacity(0.3))
                        .frame(width: 300, height: 500)
                        .blendMode(getBlendMode(for: selectedFilter))
                }
            }
        )
        renderer.scale = UIScreen.main.scale
        
        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            showingSaveAlert = true
        }
    }
    
    func sharePhoto() {
        let renderer = ImageRenderer(content:
            ZStack {
                FrameImages(displayedImages: .constant(displayedImages),
                           backgroundImage: backgroundImage,
                           showCloseButton: false)
                .frame(width: 300, height: 500)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 1)
                )
                
                // 필터 적용
                if selectedFilter != .none {
                    Rectangle()
                        .fill(selectedFilter.color.opacity(0.3))
                        .frame(width: 300, height: 500)
                        .blendMode(getBlendMode(for: selectedFilter))
                }
            }
        )
        renderer.scale = UIScreen.main.scale
        
        if let uiImage = renderer.uiImage {
            let activityVC = UIActivityViewController(activityItems: [uiImage], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true, completion: nil)
            }
        }
    }
    
    func selectBackgroundImage(_ imageName: String) {
        frameModel.changeBackgroundByName(imageName)
    }
    
    func removeImage(at index: Int) {
        frameModel.removePhoto(at: index)
        self.displayedImages = frameModel.displayedImages
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
