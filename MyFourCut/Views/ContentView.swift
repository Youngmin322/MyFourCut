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
    
    let backgroundImages = ["bg1", "bg2", "bg3", "bg4", "bg5"]
    
    var body: some View {
        VStack {
            Text("나의 네컷")
                .font(.title)
                .bold()
        }

        FrameImages(displayedImages: $displayedImages,
                    backgroundImage: backgroundImage)
        .frame(width: 300, height: 500)
        .background(
            Rectangle()
                .stroke(Color.black, lineWidth: 1)
        )
        
        // 프레임 필터 스크롤 뷰
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(backgroundImages, id: \.self) { imageName in
                    Button(action: {
                        backgroundImage = imageName
                    }) {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: backgroundImage == imageName ? 3 : 1)
                            )
                    }
                }
            }
            .padding()
        }
        
        HStack(spacing: 20) {
            PhotosPicker(
                selection: $selectedPhotos,
                maxSelectionCount: 4,
                matching: .images
            ) {
                Text("사진 고르기")
                    .padding()
                    .bold()
                    .foregroundStyle(.white)
                    .background(Color.black)
                    .cornerRadius(10)
            }
            
            Button(action: {
                savePhoto()
            }) {
                Text("저장하기")
                    .padding()
                    .bold()
                    .foregroundColor(.white)
                    .background(Color.black)
                    .cornerRadius(10)
            }
            .onChange(of: selectedPhotos) { _, _ in
                Task {
                    await loadTransferable()
                }
            }
        }
    }
    
    func loadTransferable() async {
        for (index, photoItem) in selectedPhotos.prefix(4).enumerated() {
            do {
                if let imageData = try await photoItem.loadTransferable(type: Data.self),
                    let uiImage = UIImage(data: imageData) {
                    await MainActor.run {
                        displayedImages[index] = Image(uiImage: uiImage)
                    }
                }
            } catch {
                print("이미지 로드 실패: \(error)")
            }
        }
        selectedPhotos.removeAll()
    }
    
    func savePhoto() {
        let renderer = ImageRenderer(content: ZStack {
            FrameImages(displayedImages: $displayedImages,
                        backgroundImage: backgroundImage)
            .frame(width: 300, height: 500)
        })
        renderer.scale = UIScreen.main.scale
    }
}
        
#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
