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
    // 선택된 사진들을 저장하는 상태 변수
    var selectedPhotos: [PhotosPickerItem] = []
    // 화면에 표시될 이미지들을 저장하는 상태 변수 (최대 4개)
    var displayedImages: [Image?] = Array(repeating: nil, count: 4)
    // 저장 완료 알림창 표시 여부를 제어하는 상태 변수
    var showingSaveAlert = false
    // 선택된 배경 이미지를 저장하는 상태 변수
    var backgroundImage: String? = "bg0"
    
    let backgroundImages = ["bg0", "bg1", "bg2", "bg3", "bg4", "bg5"]
    
    init(initialImages: [Image?]? = nil) {
        displayedImages = initialImages ?? Array(repeating: nil, count: 4)
    }
    
    func loadTransferable() async {
        for (index, photoItem) in selectedPhotos.prefix(4).enumerated() {
            do {
                if let imageData = try await photoItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: imageData) {
                    displayedImages[index] = Image(uiImage: uiImage)
                }
            } catch {
                print("이미지 로드 실패: \(error)")
            }
        }
        selectedPhotos.removeAll()
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
        backgroundImage = imageName
    }
    
    func removeImage(at index: Int) {
        guard index < displayedImages.count else { return }
        displayedImages[index] = nil
    }
}
