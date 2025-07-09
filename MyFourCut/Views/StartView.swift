//
//  StartView.swift
//  MyFourCut
//
//  Created by 조영민 on 2/6/25.
//

import SwiftUI

struct StartView: View {
    @State private var viewModel = StartViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // 로고 영역
                    VStack(spacing: 10) {
                        // 4개의 사각형으로 이루어진 로고
                        HStack(spacing: 8) {
                            ForEach(0..<2) { _ in
                                VStack(spacing: 8) {
                                    ForEach(0..<2) { _ in
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.black)
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Image(systemName: ["face.smiling", "star.fill", "heart.fill", "hand.peace"][.random(in: 0...3)])
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 30))
                                            )
                                    }
                                }
                            }
                        }
                        
                        Text("나만의 네컷")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    // 버튼 영역
                    VStack(spacing: 16) {
                        // NEW 배지
                        HStack {
                            Spacer()
                            Text("NEW 앨범 이미지로 나만의 네컷 만들기!")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.blue)
                                )
                            Spacer()
                        }
                        
                        NavigationLink(value: 2) {
                            Text("앨범에서 선택")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.black)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        
                        NavigationLink(value: 1) {
                            Text("촬영하기")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                        }
                        .padding(.horizontal, 40)
                        
                        // 생성된 네컷 개수
                        Text("생성된 네컷 캐쉬 : 0")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                        .frame(height: 60)
                }
            }
            .navigationTitle("")
            .navigationDestination(for: Int.self) { value in
                if value == 1 {
                    CameraView(displayedImages: $viewModel.displayedImages)
                } else {
                    ContentView(initialImages: nil)
                }
            }
        }
    }
}

#Preview {
    StartView()
}
