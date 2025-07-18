//
//  FrameFilterView.swift
//  MyFourCut
//
//  Created by 조영민 on 7/9/25.
//

import SwiftUI

struct FrameFilterView: View {
    var viewModel: ContentViewModel
    @Binding var currentStep: ContentStep
    @State private var frameFilterViewModel = FrameFilterViewModel()
    @State private var showingCustomFrameSelection = false
    @StateObject private var customFrameService = CustomFrameService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView {
                framePreview
                selectionSection
                Spacer()
                saveButton
            }
        }
        .alert("저장 완료", isPresented: $frameFilterViewModel.showingSaveAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("이미지가 앨범에 저장되었습니다.")
        }
        .sheet(isPresented: $showingCustomFrameSelection) {
            CustomFrameSelectionView(isPresented: $showingCustomFrameSelection) { newFrame in
                // 새 프레임이 추가되면 자동으로 선택
                viewModel.selectBackground(newFrame)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                currentStep = .framePreview
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
                    .font(.system(size: 20, weight: .medium))
            }
            
            Spacer()
            
            Text("프레임")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {
                frameFilterViewModel.sharePhoto(
                    displayedImages: viewModel.displayedImages,
                    selectedBackground: viewModel.selectedBackground
                )
            }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.black)
                    .font(.system(size: 20))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
        .background(Color.white)
    }
    
    private var framePreview: some View {
        ZStack {
            FrameImages(
                displayedImages: Bindable(viewModel).displayedImages,
                selectedBackground: viewModel.selectedBackground,
                showCloseButton: true
            )
            .frame(width: 300, height: 500)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 1)
            )
            
            if frameFilterViewModel.selectedFilter != .none {
                Rectangle()
                    .fill(frameFilterViewModel.selectedFilter.color.opacity(0.3))
                    .frame(width: 300, height: 500)
                    .blendMode(getBlendMode(for: frameFilterViewModel.selectedFilter))
            }
        }
        .padding(.vertical, 20)
    }
    
    private var selectionSection: some View {
        VStack(spacing: 0) {
            tabBar
            optionsScrollView
        }
    }
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "프레임",
                isSelected: frameFilterViewModel.currentTab == .frame,
                action: { frameFilterViewModel.selectTab(.frame) }
            )
            
            TabButton(
                title: "필터",
                isSelected: frameFilterViewModel.currentTab == .filter,
                action: { frameFilterViewModel.selectTab(.filter) }
            )
        }
        .background(Color.gray.opacity(0.1))
    }
    
    private var optionsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if frameFilterViewModel.currentTab == .frame {
                    frameOptions
                } else {
                    filterOptions
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var frameOptions: some View {
        // 기본 프레임들
        ForEach(BackgroundModel.defaultBackgrounds, id: \.id) { background in
            FrameOptionButton(
                background: background,
                isSelected: viewModel.selectedBackground.id == background.id,
                action: { viewModel.selectBackground(background) }
            )
        }
        
        // 커스텀 프레임 추가 버튼
        Button(action: {
            showingCustomFrameSelection = true
        }) {
            VStack {
                Circle()
                    .stroke(Color.gray, style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    )
                
                Text("추가")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        
        // 커스텀 프레임들
        ForEach(customFrameService.customFrames, id: \.id) { background in
            CustomFrameOptionButton(
                background: background,
                isSelected: viewModel.selectedBackground.id == background.id,
                action: { viewModel.selectBackground(background) },
                onDelete: { customFrameService.removeCustomFrame(background) }
            )
        }
    }
    
    @ViewBuilder
    private var filterOptions: some View {
        ForEach(FilterType.allCases, id: \.self) { filter in
            FilterOptionButton(
                filter: filter,
                isSelected: frameFilterViewModel.selectedFilter == filter,
                action: { frameFilterViewModel.selectFilter(filter) }
            )
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            frameFilterViewModel.savePhoto(
                displayedImages: viewModel.displayedImages,
                selectedBackground: viewModel.selectedBackground
            )
        }) {
            Text("사진 저장")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.black)
                .cornerRadius(10)
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
        .padding(.top, 10)
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

// Supporting Views
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .black : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
    }
}

struct FrameOptionButton: View {
    let background: BackgroundModel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                if let imageName = background.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color.black : Color.gray,
                                    lineWidth: isSelected ? 3 : 1
                                )
                        )
                }
                
                Text(background.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(.black)
            }
        }
    }
}

struct CustomFrameOptionButton: View {
    let background: BackgroundModel
    let isSelected: Bool
    let action: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack {
            ZStack {
                if let customImage = background.customImage {
                    Image(uiImage: customImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color.black : Color.gray,
                                    lineWidth: isSelected ? 3 : 1
                                )
                        )
                }
                
                // 삭제 버튼
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onDelete) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .background(Color.white, in: Circle())
                                .font(.system(size: 16))
                        }
                    }
                    Spacer()
                }
                .frame(width: 60, height: 60)
            }
            .onTapGesture {
                action()
            }
            
            Text(background.displayName)
                .font(.system(size: 12))
                .foregroundColor(.black)
                .lineLimit(1)
        }
    }
}

struct FilterOptionButton: View {
    let filter: FilterType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Circle()
                    .fill(filter.color)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? Color.black : Color.gray,
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
                
                Text(filter.name)
                    .font(.system(size: 12))
                    .foregroundColor(.black)
            }
        }
    }
}
