//
//  ContentViewModel.swift
//  MyFourCut
//
//  Created by 조영민 on 6/24/25.
//

import SwiftUI
import PhotosUI

@MainActor
@Observable
class ContentViewModel {
    private var frameModel = FourCutFrameModel()
    var selectedPhotos: [PhotosPickerItem] = []
    var showingSaveAlert = false
    var displayedImages: [Image?] = []
    var backgroundImage: String? {
        frameModel.selectedBackground.imageName
    }
    
    let backgroundImages = BackgroundModel.defaultBackgrounds.map { $0.imageName }
    
    init(initialImages: [Image?]? = nil) {
        if let images = initialImages {
            frameModel.setInitialImages(images)
            self.displayedImages = frameModel.displayedImages
        }
    }
    
    func loadTransferable() async {
        // 현재 비어있는 자리들을 찾기
        var newImages: [Image] = []
        
        for photoItem in selectedPhotos {
            do {
                if let imageData = try await photoItem.loadTransferable(type: Data.self),
                   let uiImages = UIImage(data: imageData) {
                    let image = Image(uiImage: uiImages)
                    newImages.append(image)
                }
            } catch {
                print("이미지 로드 실패: \(error)")
            }
        }
        
        // 현재 displayedImages 복사
        var updatedImages = displayedImages
        
        // 배열이 4개 미만이면 nil로 채우기
        while updatedImages.count < 4 {
            updatedImages.append(nil)
        }
        
        // 빈 자리 찾기
        var emptyIndices: [Int] = []
        for i in 0..<4 {
            if updatedImages[i] == nil {
                emptyIndices.append(i)
            }
        }
        print("빈 인덱스: \(emptyIndices)")
        print("새 이미지 개수: \(newImages.count)")
        print("처리 전 displayedImages: \(updatedImages.map { $0 == nil ? "nil" : "Image" })")
        
        // 새 이미지들을 빈 자리에 순서대로 배치
        for (newImageIndex, newImage) in newImages.enumerated() {
            if newImageIndex < emptyIndices.count {
                let targetIndex = emptyIndices[newImageIndex]
                updatedImages[targetIndex] = newImage
                print("사진을 \(targetIndex)번 자리에 배치")
            }
        }
        
        selectedPhotos.removeAll()
        
        // displayedImages 직접 업데이트
        self.displayedImages = updatedImages
        
        // frameModel도 동기화 (필요한 경우)
        frameModel.setImages(updatedImages)
        
        print("처리 후 displayedImages: \(self.displayedImages.map { $0 == nil ? "nil" : "Image" })")
    }
    
    func savePhoto() {
        let renderer = ImageRenderer(content: ZStack {
            FrameImages(displayedImages: .constant(displayedImages),
                        backgroundImage: backgroundImage,
                        showCloseButton: false)
            .frame(width: 300, height: 500)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 1)
            )
        })
        renderer.scale = UIScreen.main.scale
        
        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            showingSaveAlert = true
        }
    }
    
    func sharePhoto() {
        let renderer = ImageRenderer(content: ZStack {
            FrameImages(displayedImages: .constant(displayedImages),
                        backgroundImage: backgroundImage,
                        showCloseButton: false)
            .frame(width: 300, height: 500)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 1)
            )
        })
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
}
