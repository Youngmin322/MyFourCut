//
//  ContentView.swift
//  MyFourCut
//
//  Created by 조영민 on 2/4/25.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var viewModel: ContentViewModel
    @State private var showingPhotoPicker = false
    @State private var selectedPhotosForPicker: [PhotosPickerItem] = []
    @State private var currentStep: ContentStep = .photoSelection
    @Environment(\.dismiss) private var dismiss
    
    enum ContentStep {
        case photoSelection
        case framePreview
        case frameAndFilter
    }
    
    init(initialImages: [Image?]? = nil) {
        _viewModel = State(initialValue: ContentViewModel(initialImages: initialImages))
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            switch currentStep {
            case .photoSelection:
                photoSelectionView
            case .framePreview:
                framePreviewView
            case .frameAndFilter:
                frameAndFilterView
            }
        }
        .navigationBarBackButtonHidden(true)
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotosForPicker,
            maxSelectionCount: 8,
            matching: .images
        )
        .onChange(of: selectedPhotosForPicker) { _, newItems in
            Task {
                await loadSelectedPhotos(newItems)
            }
        }
    }
    
    // MARK: - Photo Selection View (Step 1)
    var photoSelectionView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.system(size: 20, weight: .medium))
                    }
                    
                    Spacer()
                    
                    Text("나만의 네컷")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    // 빈 공간 (레이아웃 균형)
                    Color.clear.frame(width: 30)
                }
                .padding()
                .background(Color.white)
                
                // Photo Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2)
                    ], spacing: 2) {
                        // 추가 버튼
                        Button(action: {
                            showingPhotoPicker = true
                        }) {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: (geometry.size.width - 8) / 3, height: (geometry.size.width - 8) / 3)
                            .background(Color.gray.opacity(0.1))
                        }
                        
                        // 선택된 사진들
                        ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                            Button(action: {
                                // 사진을 탭하면 선택 해제
                                viewModel.removeSelectedImage(at: index)
                            }) {
                                ZStack(alignment: .topTrailing) {
                                    image
                                        .resizable()
                                        .aspectRatio(1, contentMode: .fill)
                                        .frame(width: (geometry.size.width - 8) / 3, height: (geometry.size.width - 8) / 3)
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
                    }
                    .padding(.horizontal, 2)
                    .padding(.top, 2)
                }
                .frame(maxHeight: .infinity)
                
                // Bottom Bar
                VStack(spacing: 12) {
                    Text("사진 선택 (\(viewModel.selectedImages.count)/8)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        if viewModel.selectedImages.count >= 4 {
                            currentStep = .framePreview
                        }
                    }) {
                        Text("다음")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                viewModel.selectedImages.count >= 4
                                ? Color.black
                                : Color.gray.opacity(0.3)
                            )
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.selectedImages.count < 4)
                }
                .padding()
                .background(Color.white)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    // MARK: - Frame Preview View (Step 2)
    var framePreviewView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { currentStep = .photoSelection }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .font(.system(size: 20, weight: .medium))
                }
                
                Spacer()
            }
            .padding()
            .background(Color.white)
            
            // Frame Preview
            VStack(spacing: 20) {
                FrameImages(
                    displayedImages: .constant(Array(viewModel.selectedImages.prefix(4))),
                    backgroundImage: viewModel.backgroundImage,
                    showCloseButton: false
                )
                .frame(width: 300, height: 500)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 1)
                )
                
                // Selected photos scroll view
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                            ZStack {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 90)
                                    .clipped()
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                index < 4 ? Color.blue : Color.gray,
                                                lineWidth: index < 4 ? 3 : 1
                                            )
                                    )
                                
                                Text("\(index + 1)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                                    .background(index < 4 ? Color.blue : Color.gray)
                                    .clipShape(Circle())
                                    .offset(x: -20, y: -35)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 100)
            }
            
            Spacer()
            
            // Bottom Button
            Button(action: {
                currentStep = .frameAndFilter
            }) {
                Text("다음")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.black)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
    
    // MARK: - Frame and Filter View (Step 3)
    var frameAndFilterView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { currentStep = .framePreview }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .font(.system(size: 20, weight: .medium))
                }
                
                Spacer()
                
                Text("프레임")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                // 공유 버튼
                Button(action: { viewModel.sharePhoto() }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.black)
                        .font(.system(size: 20))
                }
            }
            .padding()
            .background(Color.white)
            
            // Frame Preview
            FrameImages(
                displayedImages: $viewModel.displayedImages,
                backgroundImage: viewModel.backgroundImage
            )
            .frame(width: 300, height: 500)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 1)
            )
            .padding(.vertical, 20)
            
            // Filter/Frame Selection
            VStack(spacing: 0) {
                // Tab Selection
                HStack {
                    Button(action: {
                        viewModel.currentTab = .frame
                    }) {
                        Text("프레임")
                            .font(.system(size: 16, weight: viewModel.currentTab == .frame ? .bold : .regular))
                            .foregroundColor(viewModel.currentTab == .frame ? .black : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    
                    Button(action: {
                        viewModel.currentTab = .filter
                    }) {
                        Text("필터")
                            .font(.system(size: 16, weight: viewModel.currentTab == .filter ? .bold : .regular))
                            .foregroundColor(viewModel.currentTab == .filter ? .black : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .background(Color.gray.opacity(0.1))
                
                // Options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        if viewModel.currentTab == .frame {
                            ForEach(viewModel.backgroundImages, id: \.self) { imageName in
                                Button(action: {
                                    viewModel.selectBackgroundImage(imageName)
                                }) {
                                    VStack {
                                        Image(imageName)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        viewModel.backgroundImage == imageName ? Color.black : Color.gray,
                                                        lineWidth: viewModel.backgroundImage == imageName ? 3 : 1
                                                    )
                                            )
                                        
                                        Text(frameNameForImage(imageName))
                                            .font(.system(size: 12))
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                        } else {
                            // 필터 옵션들
                            ForEach(FilterType.allCases, id: \.self) { filter in
                                Button(action: {
                                    viewModel.selectedFilter = filter
                                }) {
                                    VStack {
                                        Circle()
                                            .fill(filter.color)
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        viewModel.selectedFilter == filter ? Color.black : Color.gray,
                                                        lineWidth: viewModel.selectedFilter == filter ? 3 : 1
                                                    )
                                            )
                                        
                                        Text(filter.name)
                                            .font(.system(size: 12))
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            
            Spacer()
            
            // Save Button
            Button(action: {
                viewModel.savePhoto()
            }) {
                Text("사진 저장")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.black)
                    .cornerRadius(10)
            }
            .padding()
        }
        .alert("저장 완료", isPresented: $viewModel.showingSaveAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("이미지가 앨범에 저장되었습니다.")
        }
    }
    
    // MARK: - Helper Methods
    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                let image = Image(uiImage: uiImage)
                viewModel.addSelectedImage(image)
            }
        }
        selectedPhotosForPicker.removeAll()
    }
    
    private func frameNameForImage(_ imageName: String) -> String {
        switch imageName {
        case "bg0": return "기본"
        case "bg1": return "그림"
        case "bg2": return "하트"
        case "bg3": return "구름"
        case "bg4": return "패턴"
        case "bg5": return "강아지"
        default: return "프레임"
        }
    }
}

// MARK: - Filter Type
enum FilterType: CaseIterable {
    case none, blackWhite, sepia, vintage, cool, warm
    
    var name: String {
        switch self {
        case .none: return "원본"
        case .blackWhite: return "흑백"
        case .sepia: return "세피아"
        case .vintage: return "빈티지"
        case .cool: return "차가운"
        case .warm: return "따뜻한"
        }
    }
    
    var color: Color {
        switch self {
        case .none: return .white
        case .blackWhite: return .gray
        case .sepia: return Color(red: 0.7, green: 0.5, blue: 0.3)
        case .vintage: return Color(red: 0.8, green: 0.7, blue: 0.6)
        case .cool: return Color(red: 0.6, green: 0.8, blue: 1.0)
        case .warm: return Color(red: 1.0, green: 0.8, blue: 0.6)
        }
    }
}
