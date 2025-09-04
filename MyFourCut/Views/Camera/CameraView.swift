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
            let newOrientation = UIDevice.current.orientation
            
            if newOrientation != orientation &&
                (newOrientation.isPortrait || newOrientation.isLandscape) {
                orientation = newOrientation
            }
        }
        .onAppear {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.setOrientationLock(.all)
            }
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
            Button {
                HapticService.shared.impact(.medium)
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            
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
        if uiView.previewLayer.session != session {
            uiView.previewLayer.session = session
        }
    }
}

// 근본 원인 파악을 위한 상세 디버깅
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
        
        print("🏗️ CameraPreviewUIView initialized")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func getOrientationName(_ orientation: UIDeviceOrientation) -> String {
        switch orientation {
        case .portrait: return "Portrait"
        case .portraitUpsideDown: return "PortraitUpsideDown"
        case .landscapeLeft: return "LandscapeLeft"
        case .landscapeRight: return "LandscapeRight"
        case .faceUp: return "FaceUp"
        case .faceDown: return "FaceDown"
        default: return "Unknown"
        }
    }
    
    private func getInterfaceOrientationName(_ orientation: UIInterfaceOrientation) -> String {
        switch orientation {
        case .portrait: return "Portrait"
        case .portraitUpsideDown: return "PortraitUpsideDown"
        case .landscapeLeft: return "LandscapeLeft"
        case .landscapeRight: return "LandscapeRight"
        default: return "Unknown"
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
