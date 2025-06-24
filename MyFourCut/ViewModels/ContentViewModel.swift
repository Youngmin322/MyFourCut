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
        for (index, photoItem) in selectedPhotos.prefix(4).enumerated() {
            do {
                if let imageData = try await photoItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: imageData) {
                    let photo = PhotoModel(uiImage: uiImage)
                    frameModel.setPhoto(photo, at: index)
                }
            } catch {
                print("이미지 로드 실패: \(error)")
            }
        }
        selectedPhotos.removeAll()
        self.displayedImages = frameModel.displayedImages
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
