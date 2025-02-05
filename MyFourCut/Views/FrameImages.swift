//
//  FrameImages.swift
//  MyFourCut
//
//  Created by 조영민 on 2/4/25.
//

import SwiftUI

struct FrameImages: View {
    @Binding var displayedImages: [Image?]
    
    var backgroundImage: String?
    
    var body: some View {
        ZStack {
            // 선택된 배경 이미지 표시
            if let bgImage = backgroundImage, let uiImage = UIImage(named: bgImage) {
                Image(uiImage: uiImage)
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
                            if let image = displayedImages[index] {
                                ZStack {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 160)
                                        .clipped()
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

            // 테두리 추가
            Rectangle()
                .stroke(Color.black, lineWidth: 3) 
                .frame(width: 300, height: 500)
        }
    }
}

#Preview {
    ContentView()
}
