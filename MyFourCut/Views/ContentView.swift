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
    @Environment(\.dismiss) private var dismiss
    
    init(initialImages: [Image?]? = nil) {
        _viewModel = State(initialValue: ContentViewModel(initialImages: initialImages))
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.gray)
                            .font(.system(size: 20, weight: .medium))
                    }
                    
                    Spacer()
                    
                    Text("나의 네컷")
                        .bold()
                        .foregroundColor(.black)
                        .font(.custom("BM JUA OTF", size: 40))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .overlay(
                            HStack {
                                Spacer()
                                HStack(spacing: 16) {
                                    Button {
                                        viewModel.sharePhoto()
                                    } label: {
                                        Image(systemName: "square.and.arrow.up")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                            .foregroundStyle(.black)
                                    }
                                }
                            }
                        )
                }
                .frame(height: 40)
                .padding(.horizontal)
                
                FrameImages(displayedImages: $viewModel.displayedImages,
                            backgroundImage: viewModel.backgroundImage)
                .frame(width: 300, height: 500)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 1)
                )
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.backgroundImages, id: \.self) { imageName in
                            Button(action: {
                                viewModel.selectBackgroundImage(imageName)
                            }) {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.black, lineWidth: viewModel.backgroundImage == imageName ? 3 : 1)
                                    )
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.white)
                
                HStack(spacing: 20) {
                    PhotosPicker(
                        selection: $viewModel.selectedPhotos,
                        maxSelectionCount: 4,
                        matching: .images
                    ) {
                        Text("사진 고르기")
                            .font(.system(size: 17, weight: .semibold))
                            .bold()
                            .padding()
                            .foregroundStyle(.white)
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        viewModel.savePhoto()
                    }) {
                        Text("저장하기")
                            .font(.system(size: 17, weight: .semibold))
                            .bold()
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.vertical, 20)
        }
        .onChange(of: viewModel.selectedPhotos) { _, _ in
            Task {
                await viewModel.loadTransferable()
            }
        }
        .alert("저장 완료", isPresented: $viewModel.showingSaveAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("이미지가 앨범에 저장되었습니다.")
        }
        .navigationBarBackButtonHidden(true)
    }
}
