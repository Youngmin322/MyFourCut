//
//  FramePreviewView.swift
//  MyFourCut
//
//  Created by 조영민 on 7/9/25.
//

import SwiftUI

struct FramePreviewView: View {
    @Binding var selectedImages: [Image]
    @Binding var currentStep: ContentStep
    @State private var viewModel = FramePreviewViewModel()
    let backgroundImage: String?
    var onFrameImagesSelected: (([Image]) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            framePreviewSection
            Spacer()
            bottomButton
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                currentStep = .photoSelection
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
                    .font(.system(size: 20, weight: .medium))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
    }
    
    private var framePreviewSection: some View {
        VStack(spacing: 20) {
            FrameImages(
                displayedImages: .constant(viewModel.frameImageIndices.map { selectedImages[$0] }),
                backgroundImage: backgroundImage,
                showCloseButton: false
            )
            .frame(width: 300, height: 500)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 1)
            )
            
            selectedPhotosScrollView
        }
    }
    
    private var selectedPhotosScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                    photoThumbnail(image: image, index: index)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 100)
    }
    
    private func photoThumbnail(image: Image, index: Int) -> some View {
        let isInFrame = viewModel.isImageInFrame(index)
        let framePosition = viewModel.getFramePosition(for: index)
        
        return Button(action: {
            viewModel.toggleImageSelection(index)
        }) {
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
                                isInFrame ? Color.blue : Color.gray,
                                lineWidth: isInFrame ? 3 : 1
                            )
                    )
                
                if let position = framePosition {
                    Text("\(position + 1)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .offset(x: -20, y: -35)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.gray)
                        .clipShape(Circle())
                        .offset(x: -20, y: -35)
                }
            }
        }
    }
    
    private var bottomButton: some View {
        Button(action: {
            if viewModel.canProceedToNext() {
                let orderedImages = viewModel.getOrderedImages(from: selectedImages)
                onFrameImagesSelected?(orderedImages)
                currentStep = .frameAndFilter
            }
        }) {
            Text("다음")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.canProceedToNext() ? Color.black : Color.gray.opacity(0.3))
                .cornerRadius(10)
        }
        .disabled(!viewModel.canProceedToNext())
        .padding()
    }
}
