//
//  CustomFrameSelectionView.swift
//  MyFourCut
//
//  Created by 조영민 on 7/18/25.
//

import SwiftUI
import Photos

struct CustomFrameSelectionView: View {
    @Binding var isPresented: Bool
    @State private var selectedAsset: PHAsset?
    @State private var frameName: String = ""
    @State private var showingNameInput = false
    @State private var galleryImages: [PHAsset] = []
    @State private var isLoading = false
    @State private var hasPermission = false
    let onFrameAdded: (BackgroundModel) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    loadingView
                } else if hasPermission {
                    galleryContentView
                } else {
                    permissionDeniedView
                }
            }
            .navigationTitle("프레임 추가")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("취소") {
                    isPresented = false
                },
                trailing: Button("완료") {
                    if selectedAsset != nil {
                        showingNameInput = true
                    }
                }
                .disabled(selectedAsset == nil)
            )
        }
        .onAppear {
            Task {
                await requestPermissionAndLoadImages()
            }
        }
        .alert("프레임 이름", isPresented: $showingNameInput) {
            TextField("프레임 이름을 입력하세요", text: $frameName)
            Button("취소", role: .cancel) { }
            Button("추가") {
                addCustomFrame()
            }
            .disabled(frameName.trimmed.isEmpty)
        } message: {
            Text("추가할 프레임의 이름을 입력해주세요")
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            Text("사진을 불러오는 중...")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 8)
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
            
            Button("설정으로 이동") {
                openSettings()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
    }
    
    private var galleryContentView: some View {
        VStack(spacing: 0) {
            // 선택된 이미지 미리보기
            if let selectedAsset = selectedAsset {
                selectedImagePreview(asset: selectedAsset)
                    .padding()
            }
            
            // 갤러리 그리드
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
        }
    }
    
    private func selectedImagePreview(asset: PHAsset) -> some View {
        VStack(spacing: 8) {
            Text("선택된 프레임 미리보기")
                .font(.headline)
                .foregroundColor(.black)
            
            PhotoAssetView(asset: asset, size: CGSize(width: 150, height: 250))
                .frame(width: 150, height: 250)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 2)
                )
        }
    }
    
    private func galleryImageItem(asset: PHAsset) -> some View {
        let isSelected = selectedAsset?.localIdentifier == asset.localIdentifier
        
        return ZStack {
            PhotoAssetView(asset: asset,
                          size: CGSize(width: (UIScreen.main.bounds.width - 8) / 3,
                                     height: (UIScreen.main.bounds.width - 8) / 3))
            
            if isSelected {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 24))
                    .background(Color.white, in: Circle())
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedAsset = isSelected ? nil : asset
        }
    }
    
    private func requestPermissionAndLoadImages() async {
        isLoading = true
        hasPermission = await PhotoLibraryService.shared.requestPermission()
        
        if hasPermission {
            galleryImages = PhotoLibraryService.shared.fetchAssets()
        }
        
        isLoading = false
    }
    
    private func addCustomFrame() {
        guard let selectedAsset = selectedAsset,
              !frameName.trimmed.isEmpty else { return }
        
        Task {
            await CustomFrameService.shared.addCustomFrame(
                from: selectedAsset,
                displayName: frameName.trimmed
            )
            
            // 새로 추가된 프레임 찾기
            if let newFrame = CustomFrameService.shared.customFrames.first(where: { $0.displayName == frameName.trimmed }) {
                await MainActor.run {
                    onFrameAdded(newFrame)
                    isPresented = false
                }
            }
        }
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}
