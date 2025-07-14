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
    var showCloseButton: Bool = true
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
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
