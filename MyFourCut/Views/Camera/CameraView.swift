//
//  CameraView.swift
//  MyFourCut
//

import SwiftUI
import UIKit
import AVFoundation

struct CameraView: View {
    @State private var viewModel = CameraViewModel()
    @Binding var displayedImages: [Image?]
    @Environment(\.dismiss) var dismiss
    @State private var orientation = UIDevice.current.orientation
    
    var body: some View {
        ZStack {
            CameraPreview(session: viewModel.session)
                .ignoresSafeArea()
            
            if viewModel.isCountingDown {
                countdownOverlay
            }
            
            VStack {
                Spacer()
                photoPreviewSection
                cameraControlSection
            }
        }
        .task {
            await viewModel.checkCameraAccess()
        }
        .onDisappear {
            viewModel.resetImages()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            orientation = UIDevice.current.orientation
        }
        .onAppear {
            // 카메라 화면에서는 모든 방향 허용
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.setOrientationLock(.all)
            }
        }
        .onDisappear {
            // 카메라 화면을 벗어나면 필요에 따라 제한 (예: 세로모드만)
            // if let delegate = UIApplication.shared.delegate as? AppDelegate {
            //     delegate.setOrientationLock(.portrait)
            // }
        }
        .navigationDestination(isPresented: $viewModel.shouldNavigateToContent) {
            ContentView(initialImages: viewModel.displayedImages)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray)
                        .font(.system(size: 20, weight: .medium))
                }
            }
        }
        .onChange(of: viewModel.displayedImages) { _, newImages in
            displayedImages = newImages
            if !newImages.contains(where: { $0 == nil }) {
                viewModel.shouldNavigateToContent = true
            }
        }
        .overlay {
            if viewModel.cameraAccessDenied {
                cameraAccessDeniedOverlay
            }
        }
    }
    
    private var countdownOverlay: some View {
        Text("\(viewModel.countDown)")
            .font(.system(size: 100, weight: .bold))
            .bold()
            .foregroundColor(.red)
            .padding()
            .transition(.scale)
    }
    
    private var photoPreviewSection: some View {
        HStack {
            ForEach(0..<4) { index in
                if let image = viewModel.displayedImages[index] {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 60, height: 80)
                }
            }
        }
        .padding()
    }
    
    private var cameraControlSection: some View {
        HStack(spacing: 60) {
            // 닫기 버튼
            Button {
                HapticService.shared.impact(.medium)
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            
            // 사진 촬영 버튼
            Button {
                viewModel.capturePhoto()
            } label: {
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 65, height: 65)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 50, height: 50)
                    )
            }
            
            // 카메라 전환 버튼
            Button {
                viewModel.switchCamera()
            } label: {
                Image(systemName: "camera.rotate.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
        }
        .padding(.bottom, 30)
    }
    
    private var cameraAccessDeniedOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                
                Text("카메라 접근이 차단되어 있어요")
                    .font(.title3)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Button {
                    viewModel.openSettings()
                } label: {
                    Text("설정에서 권한 허용하기")
                        .foregroundColor(.black)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(16)
            .padding()
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView(session: session)
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // 세션이 변경되었을 때만 업데이트
        if uiView.previewLayer.session != session {
            uiView.previewLayer.session = session
        }
    }
}

class CameraPreviewUIView: UIView {
    private let session: AVCaptureSession
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    init(session: AVCaptureSession) {
        self.session = session
        super.init(frame: .zero)
        
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        
        // 디바이스 회전 감지
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
        updateVideoOrientation()
    }
    
    @objc private func orientationChanged() {
        DispatchQueue.main.async {
            self.updateVideoOrientation()
        }
    }
    
    private func updateVideoOrientation() {
        guard let connection = previewLayer.connection,
              connection.isVideoOrientationSupported else { return }
        
        let orientation = UIDevice.current.orientation
        let videoOrientation: AVCaptureVideoOrientation
        
        switch orientation {
        case .portrait:
            videoOrientation = .portrait
        case .portraitUpsideDown:
            videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            videoOrientation = .landscapeRight
        case .landscapeRight:
            videoOrientation = .landscapeLeft
        default:
            videoOrientation = .portrait
        }
        
        connection.videoOrientation = videoOrientation
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

#Preview {
    CameraView(displayedImages: .constant([nil, nil, nil, nil]))
}
