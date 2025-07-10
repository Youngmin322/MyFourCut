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
                PhotoSelectionView(
                    selectedImages: $viewModel.selectedImages,
                    currentStep: $currentStep
                )
            case .framePreview:
                FramePreviewView(
                    selectedImages: $viewModel.selectedImages,
                    currentStep: $currentStep,
                    backgroundImage: viewModel.backgroundImage,
                    onFrameImagesSelected: { orderedImages in
                        // 프레임에 선택된 이미지들을 순서대로 viewModel에 저장
                        viewModel.updateFrameImages(with: orderedImages)
                    }
                )
            case .frameAndFilter:
                FrameFilterView(
                    viewModel: viewModel,
                    currentStep: $currentStep
                )
            }
        }
        .navigationBarBackButtonHidden(true)
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
