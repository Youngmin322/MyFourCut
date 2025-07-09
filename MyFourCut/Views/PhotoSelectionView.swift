//
//  PhotoSelectionView.swift
//  MyFourCut
//
//  Created by 조영민 on 7/9/25.
//

import SwiftUI
import PhotosUI

struct PhotoSelectionView: View {
    @Binding var selectedImages: [Image]
    @Binding var currentStep: ContentView.ContentStep
    @State private var showingPhotoPicker = false
    @State private var selectedPhotosForPicker: [PhotosPickerItem] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Photo Grid
                photoGrid(geometry: UIScreen.main.bounds)
                
                // Bottom Bar
                bottomBar
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotosForPicker,
            maxSelectionCount: 8 - selectedImages.count,
            matching: .images
        )
        .onChange(of: selectedPhotosForPicker) { _, newItems in
            Task {
                await loadSelectedPhotos(newItems)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
                    .font(.system(size: 20, weight: .medium))
            }
            
            Spacer()
            
            Text("나의 네컷")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
    
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
        .background(Color.white)
    }
    
    private func photoGrid(geometry: CGRect) -> some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2)
            ], spacing: 2) {
                // 추가 버튼
                addPhotoButton(size: (geometry.size.width - 8) / 3)
                
                // 선택된 사진들
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                    selectedPhotoItem(
                        image: image,
                        index: index,
                        size: (geometry.size.width - 8) / 3
                    )
                }
            }
            .padding(.horizontal, 2)
            .padding(.top, 16)
            
            // 빈 공간을 위한 Spacer 추가
            Spacer(minLength: 100)
        }
    }
    
    private func addPhotoButton(size: CGFloat) -> some View {
        Button(action: {
            showingPhotoPicker = true
        }) {
            VStack {
                Image(systemName: "plus")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
            }
            .frame(width: size, height: size)
            .background(Color.gray.opacity(0.1))
        }
    }
    
    private func selectedPhotoItem(image: Image, index: Int, size: CGFloat) -> some View {
        Button(action: {
            selectedImages.remove(at: index)
        }) {
            ZStack(alignment: .topTrailing) {
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipped()
                
                // 선택 순서 표시
                Text("\(index + 1)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .padding(4)
            }
        }
    }
    
    private var bottomBar: some View {
        VStack(spacing: 12) {
            Text("사진 선택 (\(selectedImages.count)/8)")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Button(action: {
                if selectedImages.count >= 4 {
                    currentStep = .framePreview
                }
            }) {
                Text("다음")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        selectedImages.count >= 4
                        ? Color.black
                        : Color.gray.opacity(0.3)
                    )
                    .cornerRadius(10)
            }
            .disabled(selectedImages.count < 4)
        }
        .padding()
        .background(Color.white)
    }
    
    private func getSafeAreaTop() -> CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.top
        }
        return 44 // 기본값
    }
    
    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                let image = Image(uiImage: uiImage)
                selectedImages.append(image)
            }
        }
        selectedPhotosForPicker.removeAll()
    }
}

#Preview {
    PhotoSelectionView(
        selectedImages: .constant([]),
        currentStep: .constant(.photoSelection)
    )
}
