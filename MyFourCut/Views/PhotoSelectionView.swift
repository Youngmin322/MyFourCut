//
//  PhotoSelectionView.swift
//  MyFourCut
//
//  Created by 조영민 on 7/9/25.
//

import SwiftUI
import PhotosUI
import Photos

struct PhotoSelectionView: View {
    @Binding var selectedImages: [Image]
    @Binding var currentStep: ContentView.ContentStep
    @State private var galleryImages: [PHAsset] = []
    @State private var selectedAssets: [PHAsset] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Gallery Grid (빨간색 영역)
                galleryGrid
                
                // Selected Photos Display
                selectedPhotosDisplay
                
                // Bottom Bar
                bottomBar
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            requestPhotoLibraryPermission()
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
            
            Text("앨범")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
        .background(Color.white)
    }
    
    private var galleryGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2)
            ], spacing: 2) {
                ForEach(galleryImages, id: \.localIdentifier) { asset in
                    galleryImageItem(asset: asset)
                }
            }
            .padding(.horizontal, 2)
        }
        .background(Color.red.opacity(0.1)) // 갤러리 영역 표시용
        .frame(height: UIScreen.main.bounds.height * 0.5) // 화면의 50% 높이
    }
    
    private func galleryImageItem(asset: PHAsset) -> some View {
        let isSelected: Bool = selectedAssets.contains(asset)
        let selectionIndex: Int? = selectedAssets.firstIndex(of: asset)
        
        return Button(action: {
            if isSelected {
                selectedAssets.removeAll { $0 == asset }
                updateSelectedImages()
            } else if selectedAssets.count < 8 {
                selectedAssets.append(asset)
                updateSelectedImages()
            }
        }) {
            ZStack(alignment: .topTrailing) {
                PhotoAssetView(asset: asset,
                              size: CGSize(width: (UIScreen.main.bounds.width - 8) / 3,
                                         height: (UIScreen.main.bounds.width - 8) / 3))
                
                if isSelected, let index = selectionIndex {
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
    }
    
    private var selectedPhotosDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("최소 4장의 사진을 선택해 주세요. (\(selectedAssets.count)/8)")
                .font(.system(size: 14))
                .foregroundColor(.black)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(selectedAssets.enumerated()), id: \.offset) { index, asset in
                        selectedPhotoThumbnail(asset: asset, index: index)
                    }
                    
                    // 빈 슬롯들 (회색 네모칸)
                    ForEach(selectedAssets.count..<8, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func selectedPhotoThumbnail(asset: PHAsset, index: Int) -> some View {
        Button(action: {
            selectedAssets.remove(at: index)
            updateSelectedImages()
        }) {
            PhotoAssetView(asset: asset, size: CGSize(width: 60, height: 60))
                .cornerRadius(8)
        }
    }
    
    private var bottomBar: some View {
        Button(action: {
            if selectedAssets.count >= 4 {
                currentStep = .framePreview
            }
        }) {
            Text("다음")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    selectedAssets.count >= 4
                    ? Color.black
                    : Color.gray.opacity(0.3)
                )
                .cornerRadius(10)
        }
        .disabled(selectedAssets.count < 4)
        .padding()
        .background(Color.white)
    }
    
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    loadGalleryImages()
                }
            }
        }
    }
    
    private func loadGalleryImages() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        galleryImages = []
        fetchResult.enumerateObjects { asset, _, _ in
            galleryImages.append(asset)
        }
    }
    
    private func updateSelectedImages() {
        selectedImages.removeAll()
        
        for asset in selectedAssets {
            let manager = PHImageManager.default()
            let option = PHImageRequestOptions()
            option.isSynchronous = true
            option.deliveryMode = .highQualityFormat
            
            manager.requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: option) { image, _ in
                if let image = image {
                    selectedImages.append(Image(uiImage: image))
                }
            }
        }
    }
}

// PhotoAssetView - 완전히 다른 구조로 변경
struct PhotoAssetView: View {
    let asset: PHAsset
    let size: CGSize
    
    @State private var uiImage: UIImage?
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size.width, height: size.height)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.deliveryMode = .opportunistic
        
        manager.requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: option) { image, _ in
            DispatchQueue.main.async {
                self.uiImage = image
            }
        }
    }
}

#Preview {
    PhotoSelectionView(
        selectedImages: .constant([]),
        currentStep: .constant(.photoSelection)
    )
}
