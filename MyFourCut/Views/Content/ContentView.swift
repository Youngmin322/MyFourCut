//
//  ContentView.swift
//  MyFourCut
//
//  Created by 조영민 on 2/4/25.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel: ContentViewModel
    @State private var currentStep: ContentStep = .photoSelection
    @Environment(\.dismiss) private var dismiss
    
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
