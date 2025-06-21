//
//  QRShare.swift
//  MyFourCut
//
//  Created by 조영민 on 2/22/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRShare: View {
    @State private var qrCodeImage: UIImage?
    @State private var isSharing = false
    @State private var isUploading = false
    @State private var shareURL: String = ""
    @State private var errorMessage: String?
    @State private var showError = false
    
    let fourCutImage: UIImage
    
    var body: some View {
        VStack(spacing: 20) {
            Text("QR 코드로 공유하기")
                .font(.title)
                .bold()
            
            if isUploading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                Text("이미지 업로드 중...")
            } else if let qrImage = qrCodeImage {
                Image(uiImage: qrImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()
                
                Text("QR 코드를 스캔하여 사진을 확인하세요")
                    .font(.subheadline)
                
                Text(shareURL)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    isSharing = true
                }) {
                    Label("공유하기", systemImage: "square.and.arrow.up")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.black)
                        .cornerRadius(10)
                }
                .sheet(isPresented: $isSharing) {
                    if let qrImage = qrCodeImage {
                        ShareSheet(items: [qrImage, shareURL])
                    }
                }
            } else {
                Button(action: {
                    uploadImage()
                }) {
                    Text("QR 코드 생성하기")
                        .bold()
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.black)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .onAppear {
            // 자동으로 이미지 업로드 시작
            uploadImage()
        }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
    }
    
    func uploadImage() {
        isUploading = true
        errorMessage = nil
        
        // 이미지 압축
        let imageWithoutAlpha = removeAlpha(from: fourCutImage)
        
        guard let imageData = imageWithoutAlpha.jpegData(compressionQuality: 0.7) else {
            errorMessage = "이미지 변환에 실패했습니다."
            showError = true
            isUploading = false
            return
        }
        
        // 서버 URL (로컬 테스트용)
        // 실제 기기에서 테스트할 때는 컴퓨터의 IP 주소로 변경 필요
        guard let url = URL(string: "http://172.30.1.85:8080/upload") else {
            errorMessage = "잘못된 URL입니다."
            showError = true
            isUploading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = imageData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isUploading = false
                
                if let error = error {
                    errorMessage = "네트워크 오류: \(error.localizedDescription)"
                    showError = true
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = "잘못된 응답이 왔습니다."
                    showError = true
                    return
                }
                print("HTTP 응답 코드: \(httpResponse.statusCode)") // 상태 코드 출력
                if (200...299).contains(httpResponse.statusCode) {
                    // 성공적인 응답 처리
                } else {
                    errorMessage = "서버 오류가 발생했습니다. 상태 코드: \(httpResponse.statusCode)"
                    showError = true
                }
                
                guard let data = data,
                      let urlString = String(data: data, encoding: .utf8) else {
                    errorMessage = "서버 응답을 처리할 수 없습니다."
                    showError = true
                    return
                }
                
                // 공유 URL 생성
                // 본 URL에 'share/'를 추가하여 서버의 share 엔드포인트를 사용
                if let id = urlString.split(separator: "/").last {
                    shareURL = "http://172.30.1.85:8080/share/\(id)"
                    generateQRCode(from: shareURL)
                } else {
                    errorMessage = "URL 형식이 잘못되었습니다."
                    showError = true
                }
            }
        }.resume()
    }
    
    func removeAlpha(from image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true  // 알파 제거!
        
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
    
    func generateQRCode(from string: String) {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H" // 오류 수정 레벨 (L, M, Q, H)
        
        if let outputImage = filter.outputImage {
            let scale = 10.0
            let scaleX = UIScreen.main.scale * scale
            let transform = CGAffineTransform(scaleX: scaleX, y: scaleX)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrCodeImage = UIImage(cgImage: cgImage)
            }
        }
    }
}

// 공유 시트를 위한 도우미 구조체
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    struct QRShare {
    }
}
