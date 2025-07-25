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
    @Binding var currentStep: ContentStep
    @State private var viewModel = PhotoSelectionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            if viewModel.isLoading {
                loadingView
            } else if viewModel.hasPermission {
                galleryContentView
            } else {
                permissionDeniedView
            }
        }
        .background(Color.white)
        .ignoresSafeArea(.container, edges: .bottom)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            Task {
                await viewModel.requestPermissionAndLoadImages()
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
            
            Text("앨범")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, -60)
        .background(Color.white)
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            Text("사진을 불러오는 중...")
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
        }
    }
    
    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("사진 접근 권한이 필요합니다")
                .font(.title3)
                .foregroundColor(.black)
            
            Text("설정에서 사진 접근을 허용해주세요")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
    
    private var galleryContentView: some View {
        VStack(spacing: 0) {
            galleryGrid
            selectedPhotosDisplay
            bottomBar
        }
    }
    
    private var galleryGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2)
            ], spacing: 2) {
                ForEach(viewModel.galleryImages, id: \.localIdentifier) { asset in
                    galleryImageItem(asset: asset)
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(height: UIScreen.main.bounds.height * 0.5)
    }
    
    private func galleryImageItem(asset: PHAsset) -> some View {
        let isSelected = viewModel.isAssetSelected(asset)
        let selectionIndex = viewModel.getSelectionIndex(for: asset)
        
        return ZStack(alignment: .topTrailing) {
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
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.toggleAssetSelection(asset)
        }
    }
    
    private var selectedPhotosDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("사진을 4장 이상 선택해 주세요. (\(viewModel.selectedAssets.count)/8)")
                .font(.system(size: 14))
                .foregroundColor(.black)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(viewModel.selectedAssets.enumerated()), id: \.offset) { index, asset in
                        selectedPhotoThumbnail(asset: asset, index: index)
                    }
                    
                    ForEach(viewModel.selectedAssets.count..<8, id: \.self) { _ in
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
        PhotoAssetView(asset: asset, size: CGSize(width: 60, height: 60))
            .cornerRadius(8)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.removeAsset(at: index)
            }
    }
    
    private var bottomBar: some View {
        Button(action: {
            if viewModel.selectedAssets.count >= 4 {
                Task {
                    selectedImages = await viewModel.convertSelectedAssetsToImages()
                    currentStep = .framePreview
                }
            }
        }) {
            Text("다음")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    viewModel.selectedAssets.count >= 4
                    ? Color.black
                    : Color.gray.opacity(0.3)
                )
                .cornerRadius(10)
        }
        .disabled(viewModel.selectedAssets.count < 4)
        .padding()
        .background(Color.white)
    }
}

struct PhotoAssetView: View {
    let asset: PHAsset
    let size: CGSize
    
    @State private var uiImage: UIImage?
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
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
        Task {
            if let image = await PhotoLibraryService.shared.loadImage(from: asset, targetSize: CGSize(width: 200, height: 200)) {
                await MainActor.run {
                    self.uiImage = image
                }
            }
        }
    }
}
