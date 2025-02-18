//
//  StartView.swift
//  MyFourCut
//
//  Created by 조영민 on 2/6/25.
//

import SwiftUI

struct StartView: View {
    @State private var tag: Int? = nil
    @State private var displayedImages: [Image?] = Array(repeating: nil, count: 4)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                NavigationLink(value: 1) {
                    Text("촬영하기")
                        .font(.custom("BM JUA OTF", size: 20))
                        .frame(maxWidth: 250, maxHeight: 50)
                        .bold()
                        .foregroundColor(.white)
                        .background(Color.black)
                        .cornerRadius(10)
                }
                NavigationLink(value: 2) {
                    Text("네컷 바로 만들기")
                        .font(.custom("BM JUA OTF", size: 20))
                        .frame(maxWidth: 250, maxHeight: 50)
                        .bold()
                        .foregroundColor(.white)
                        .background(Color.black)
                        .cornerRadius(10)
                }
                .offset(y: 70)
            }
            .navigationTitle("")
            .navigationDestination(for: Int.self) { value in
                if value == 1 {
                    CameraView(displayedImages: $displayedImages)
                } else {
                    ContentView()
                }
            }
        }
    }
}

#Preview {
    StartView()
}
