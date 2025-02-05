//
//  ContentView.swift
//  MyFourCut
//
//  Created by 조영민 on 2/4/25.
//

import SwiftUI
import PhotosUI
import SwiftData

struct ContentView: View {
    // 선택된 사진들을 저장하는 상태 변수
    @State private var selectedPhotos: [PhotosPickerItem] = []
    // 화면에 표시될 이미지들을 저장하는 상태 변수 (최대 4개)
    @State private var displayedImages: [Image?] = Array(repeating: nil, count: 4)
    // 저장 완료 알림창 표시 여부를 제어하는 상태 변수
    @State private var showingSaveAlert = false
    // 선택된 배경 이미지를 저장하는 상태 변수
    @State private var backgroundImage: String? = nil
    
    var body: some View {
        VStack {
            Text("나의 네컷")
                .font(.title)
                .bold()
        }
        
        FrameImages(displayedImages: $displayedImages)
        
        
    }
}
    
        
#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
