//
//  FramePreviewView.swift
//  MyFourCut
//
//  Created by 조영민 on 7/9/25.
//

import SwiftUI

struct FramePreviewView: View {
    @Binding var selectedImages: [Image]
    @Binding var currentStep: ContentView.ContentStep
    let backgroundImage: String?
    
    // 프레임에 들어갈 이미지들의 인덱스를 관리
    @State private var frameImageIndices: [Int] = []
    
    // 선택된 이미지 순서를 상위 뷰로 전달하기 위한 클로저
    var onFrameImagesSelected: (([Image]) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Frame Preview
            framePreviewSection
            
            Spacer()
            
            // Bottom Button
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
            // 프레임 미리보기 - 선택된 순서대로 표시
            FrameImages(
                displayedImages: .constant(frameImageIndices.map { selectedImages[$0] }),
                backgroundImage: backgroundImage,
                showCloseButton: false
            )
            .frame(width: 300, height: 500)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 1)
            )
            
            // 선택된 사진들 스크롤 뷰
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
        let isInFrame = frameImageIndices.contains(index)
        let framePosition = frameImageIndices.firstIndex(of: index) // 프레임 내에서의 위치
        
        return Button(action: {
            // 프레임에 이미지 추가/제거 로직
            if isInFrame {
                // 이미 프레임에 있으면 제거
                frameImageIndices.removeAll { $0 == index }
            } else if frameImageIndices.count < 4 {
                // 프레임에 없고 공간이 있으면 추가
                frameImageIndices.append(index)
            }
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
                
                // 프레임에 선택된 순서 표시
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
            if frameImageIndices.count >= 4 {
                // 선택된 이미지들을 순서대로 상위 뷰로 전달
                let orderedImages = frameImageIndices.map { selectedImages[$0] }
                onFrameImagesSelected?(orderedImages)
                currentStep = .frameAndFilter
            }
        }) {
            Text("다음")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(frameImageIndices.count >= 4 ? Color.black : Color.gray.opacity(0.3))
                .cornerRadius(10)
        }
        .disabled(frameImageIndices.count < 4)
        .padding()
    }
}
