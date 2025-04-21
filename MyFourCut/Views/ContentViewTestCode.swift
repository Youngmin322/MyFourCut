//
//  ContentViewTestCode.swift
//  MyFourCut
//
//  Created by 조영민 on 2/23/25.
//

//import SwiftUI
//import PhotosUI
//import FirebaseStorage
//import FirebaseFirestore
//
//struct ContentView: View {
//    // 선택된 사진들을 저장하는 상태 변수
//    @State private var selectedPhotos: [PhotosPickerItem] = []
//    // 화면에 표시될 이미지들을 저장하는 상태 변수 (최대 4개)
//    @State private var displayedImages: [Image?] = Array(repeating: nil, count: 4)
//    // 저장 완료 알림창 표시 여부를 제어하는 상태 변수
//    @State private var showingSaveAlert = false
//    // 선택된 배경 이미지를 저장하는 상태 변수
//    @State private var backgroundImage: String? = "bg0"
//    // QR 코드 관련 상태 변수
//    @State private var showingQRAlert = false
//    @State private var qrImage: UIImage?
//    @State private var documentId: String?
//    
//    let backgroundImages = ["bg0", "bg1", "bg2", "bg3", "bg4", "bg5"]
//    
//    init(initialImages: [Image?]? = nil) {
//        _displayedImages = State(initialValue: initialImages ?? Array(repeating: nil, count: 4))
//    }
//    
//    var body: some View {
//        ZStack {
//            Color.white.ignoresSafeArea() // 다크 모드에서도 배경을 항상 흰색으로 설정
//            
//            VStack(spacing: 20) { // 버튼과 요소 간 간격 추가
//                ZStack {
//                    HStack {
//                        Spacer()
//                        Text("나의 네컷")
//                            .bold()
//                            .foregroundColor(.black)
//                            .font(.custom("BM JUA OTF", size: 40))
//                        Spacer()
//                    }
//                    
//                    HStack {
//                        Spacer()
//                        Button {
//                            shareViaQR()
//                        } label: {
//                            Image(systemName: "qrcode")
//                                .foregroundStyle(.black)
//                                .font(.system(size: 30))
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//                
//                FrameImages(displayedImages: $displayedImages, backgroundImage: backgroundImage)
//                    .frame(width: 300, height: 500)
//                    .background(Color.white)
//                    .overlay(
//                        Rectangle()
//                            .stroke(Color.black, lineWidth: 1)
//                    )
//                
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack {
//                        ForEach(backgroundImages, id: \.self) { imageName in
//                            Button(action: {
//                                backgroundImage = imageName
//                            }) {
//                                Image(imageName)
//                                    .resizable()
//                                    .scaledToFill()
//                                    .frame(width: 80, height: 50)
//                                    .clipShape(RoundedRectangle(cornerRadius: 8))
//                                    .overlay(
//                                        RoundedRectangle(cornerRadius: 8)
//                                            .stroke(Color.black, lineWidth: backgroundImage == imageName ? 3 : 1)
//                                    )
//                            }
//                        }
//                    }
//                    .padding()
//                }
//                .background(Color.white)
//                
//                HStack(spacing: 20) {
//                    PhotosPicker(
//                        selection: $selectedPhotos,
//                        maxSelectionCount: 4,
//                        matching: .images
//                    ) {
//                        Text("사진 고르기")
//                            .font(.system(size: 17, weight: .semibold))
//                            .bold()
//                            .padding()
//                            .foregroundStyle(.white)
//                            .background(Color.black)
//                            .cornerRadius(10)
//                    }
//                    
//                    Button(action: {
//                        savePhoto()
//                    }) {
//                        Text("저장하기")
//                            .font(.system(size: 17, weight: .semibold))
//                            .bold()
//                            .padding()
//                            .foregroundColor(.white)
//                            .background(Color.black)
//                            .cornerRadius(10)
//                    }
//                }
//            }
//            .padding(.vertical, 20)
//        }
//        .onChange(of: selectedPhotos) { _, _ in
//            Task {
//                await loadTransferable()
//            }
//        }
//        .alert("저장 완료", isPresented: $showingSaveAlert) {
//            Button("확인", role: .cancel) { }
//        } message: {
//            Text("이미지가 앨범에 저장되었습니다.")
//        }
//        .alert("QR 코드", isPresented: $showingQRAlert) {
//            Button("확인", role: .cancel) { }
//            if let qrImage = qrImage {
//                ShareLink(
//                    item: Image(uiImage: qrImage),
//                    preview: SharePreview("QR 코드", image: Image(uiImage: qrImage))
//                )
//            }
//        } message: {
//            if let qrImage = qrImage {
//                Image(uiImage: qrImage)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 200, height: 200)
//            }
//        }
//    }
//    
//    func loadTransferable() async {
//        for (index, photoItem) in selectedPhotos.prefix(4).enumerated() {
//            do {
//                if let imageData = try await photoItem.loadTransferable(type: Data.self),
//                   let uiImage = UIImage(data: imageData) {
//                    await MainActor.run {
//                        displayedImages[index] = Image(uiImage: uiImage)
//                    }
//                }
//            } catch {
//                print("이미지 로드 실패: \(error)")
//            }
//        }
//        selectedPhotos.removeAll()
//    }
//    
//    func savePhoto() {
//        let renderer = ImageRenderer(content: ZStack {
//            FrameImages(displayedImages: $displayedImages,
//                       backgroundImage: backgroundImage,
//                       showCloseButton: false)
//            .frame(width: 300, height: 500)
//            .background(Color.white)
//            .overlay(
//                Rectangle()
//                    .stroke(Color.black, lineWidth: 1)
//            )
//        })
//        renderer.scale = UIScreen.main.scale
//        
//        if let uiImage = renderer.uiImage {
//            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
//            showingSaveAlert = true
//        }
//    }
//    
//    private func shareViaQR() {
//        QRShare.uploadImages(displayedImages) { documentId in
//            if let id = documentId {
//                self.documentId = id
//                self.qrImage = QRShare.generateQRCode(from: id)
//                self.showingQRAlert = true
//            }
//        }
//    }
//}
//
//#Preview {
//    ContentView()
//        .modelContainer(for: Item.self, inMemory: true)
//}
