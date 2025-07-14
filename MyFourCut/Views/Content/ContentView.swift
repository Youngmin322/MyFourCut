//
//  ContentView.swift
//  MyFourCut
//
//  Created by 조영민 on 2/4/25.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel: ContentViewModel
    @State private var currentStep: ContentStep
    @Environment(\.dismiss) private var dismiss
    
    init(initialImages: [Image?]? = nil) {
        _viewModel = State(initialValue: ContentViewModel(initialImages: initialImages))
        
        // 초기 이미지가 있고 4장이 모두 있으면 framePreview부터 시작
        if let images = initialImages, images.compactMap({ $0 }).count == 4 {
            _currentStep = State(initialValue: .framePreview)
        } else {
            _currentStep = State(initialValue: .photoSelection)
        }
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
