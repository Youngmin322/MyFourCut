//
//  FrameFilterView.swift
//  MyFourCut
//
//  Created by 조영민 on 7/9/25.
//

import SwiftUI

struct FrameFilterView: View {
    var viewModel: ContentViewModel
    @Binding var currentStep: ContentView.ContentStep
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Frame Preview
            framePreview
            
            // Filter/Frame Selection
            selectionSection
            
            Spacer()
            
            // Save Button
            saveButton
        }
        .alert("저장 완료", isPresented: Bindable(viewModel).showingSaveAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("이미지가 앨범에 저장되었습니다.")
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
            
            // 공유 버튼
            Button(action: {
                viewModel.sharePhoto()
            }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.black)
                    .font(.system(size: 20))
            }
        }
        .padding()
        .background(Color.white)
    }
    
    private var framePreview: some View {
        FrameImages(
            displayedImages: Bindable(viewModel).displayedImages,
            backgroundImage: viewModel.backgroundImage,
            showCloseButton: true
        )
        .frame(width: 300, height: 500)
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color.black, lineWidth: 1)
        )
        .padding(.vertical, 20)
    }
    
    private var selectionSection: some View {
        VStack(spacing: 0) {
            // Tab Selection
            tabBar
            
            // Options
            optionsScrollView
        }
    }
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "프레임",
                isSelected: viewModel.currentTab == .frame,
                action: { viewModel.currentTab = .frame }
            )
            
            TabButton(
                title: "필터",
                isSelected: viewModel.currentTab == .filter,
                action: { viewModel.currentTab = .filter }
            )
        }
        .background(Color.gray.opacity(0.1))
    }
    
    private var optionsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if viewModel.currentTab == .frame {
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
        ForEach(viewModel.backgroundImages, id: \.self) { imageName in
            FrameOptionButton(
                imageName: imageName,
                isSelected: viewModel.backgroundImage == imageName,
                action: { viewModel.selectBackgroundImage(imageName) }
            )
        }
    }
    
    @ViewBuilder
    private var filterOptions: some View {
        ForEach(FilterType.allCases, id: \.self) { filter in
            FilterOptionButton(
                filter: filter,
                isSelected: viewModel.selectedFilter == filter,
                action: { viewModel.selectedFilter = filter }
            )
        }
    }
    
    private var saveButton: some View {
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
}

// MARK: - Supporting Views

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
    let imageName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
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
                
                Text(frameNameForImage(imageName))
                    .font(.system(size: 12))
                    .foregroundColor(.black)
            }
        }
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
