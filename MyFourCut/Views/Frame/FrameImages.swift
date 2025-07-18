//
//  FrameImages.swift
//  MyFourCut
//
//  Created by 조영민 on 2/4/25.
//

import SwiftUI

struct FrameImages: View {
    @Binding var displayedImages: [Image?]
    var selectedBackground: BackgroundModel  // BackgroundModel 사용
    var showCloseButton: Bool = true
    
    // 기존 코드와의 호환성을 위한 생성자 (deprecated)
    init(displayedImages: Binding<[Image?]>, backgroundImage: String?, showCloseButton: Bool = true) {
        self._displayedImages = displayedImages
        
        // String을 BackgroundModel로 변환
        if let backgroundImage = backgroundImage,
           let background = BackgroundModel.defaultBackgrounds.first(where: { $0.imageName == backgroundImage }) {
            self.selectedBackground = background
        } else {
            self.selectedBackground = BackgroundModel.defaultBackgrounds[0]
        }
        
        self.showCloseButton = showCloseButton
    }
    
    // 새로운 생성자 (BackgroundModel 사용)
    init(displayedImages: Binding<[Image?]>, selectedBackground: BackgroundModel, showCloseButton: Bool = true) {
        self._displayedImages = displayedImages
        self.selectedBackground = selectedBackground
        self.showCloseButton = showCloseButton
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            // 배경 이미지 렌더링
            if selectedBackground.isCustom, let customImage = selectedBackground.customImage {
                // 커스텀 이미지 사용
                Image(uiImage: customImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 500)
                    .clipped()
            } else if let imageName = selectedBackground.imageName {
                // 기본 번들 이미지 사용
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 500)
                    .clipped()
            }
            
            VStack {
                ForEach(0..<2, id: \.self) { row in
                    HStack {
                        ForEach(0..<2, id: \.self) { column in
                            let index = row * 2 + column
                            if index < displayedImages.count, let image = displayedImages[index] {
                                ZStack {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 160)
                                        .clipped()
                                    
                                    if showCloseButton {
                                        Button(action: {
                                            displayedImages[index] = nil
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.black)
                                                .frame(width: 24, height: 24)
                                        }
                                        .offset(x: -50, y: -78)
                                    }
                                }
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.6))
                                    .frame(width: 100, height: 160)
                            }
                        }
                    }
                }
                Spacer().frame(height: 90)
            }
            
            Rectangle()
                .stroke(Color.black, lineWidth: 3)
                .frame(width: 300, height: 500)
        }
    }
}
