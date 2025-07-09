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
            // 프레임 미리보기
            FrameImages(
                displayedImages: .constant(Array(selectedImages.prefix(4))),
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
    
    private var bottomButton: some View {
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
