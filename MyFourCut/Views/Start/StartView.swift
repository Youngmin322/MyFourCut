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
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    logoSection
                    Spacer()
                    buttonSection
                    
                    Spacer().frame(height: 60)
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
    
    private var logoSection: some View {
        VStack(spacing: 10) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 250, height: 250)
                .cornerRadius(20)
            
            Text("나의 네컷")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.black)
        }
    }
    
    private var buttonSection: some View {
        VStack(spacing: 16) {
            NavigationLink(value: 1) {
                Text("촬영하기")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            NavigationLink(value: 2) {
                Text("앨범에서 선택")
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
        }
    }
}
