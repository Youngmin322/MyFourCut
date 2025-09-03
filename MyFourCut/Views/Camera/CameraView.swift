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
    @State private var previewKey = UUID() // 프리뷰 강제 재생성용
    
    var body: some View {
        ZStack {
            CameraPreview(session: viewModel.session)
                .id(previewKey)
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
                // 프리뷰 강제 재생성
                previewKey = UUID()
            }
        }
        .onAppear {
            // 카메라 화면에서는 모든 방향 허용
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.setOrientationLock(.all)
            }
        }
        .onDisappear {
            
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
        
        // 방향과 미러링을 항상 업데이트
        uiView.updateRotationCoordinator()
        
        // 약간의 지연 후 다시 한번 업데이트 (비동기 처리 보장)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            uiView.updateVideoOrientation()
        }
    }
    
    // 추가: 수동으로 방향 업데이트하는 메서드
    func updateOrientation(_ uiView: CameraPreviewUIView) {
        uiView.updateVideoOrientation()
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
        
        // 카메라 전환 감지 (세션 변경 감지)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionConfigurationChanged),
            name: AVCaptureSession.didStartRunningNotification,
            object: session
        )
        
        // 초기 방향 설정
        updateVideoOrientation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
        updateVideoOrientation()
    }
    
    private func setupRotationCoordinator() {
        
    }
    
    @objc private func orientationChanged() {
        DispatchQueue.main.async {
            self.updateVideoOrientation()
        }
    }
    
    @objc private func sessionConfigurationChanged() {
        DispatchQueue.main.async {
            self.updateMirroringForCurrentCamera()
        }
    }
    
    // 외부에서 호출할 수 있는 방향 업데이트 메서드
    func updateVideoOrientation() {
        guard let connection = previewLayer.connection else { return }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let rotationAngle: CGFloat
            
            switch windowScene.interfaceOrientation {
            case .portrait:
                rotationAngle = 0
            case .portraitUpsideDown:
                rotationAngle = 180
            case .landscapeLeft:
                rotationAngle = 90
            case .landscapeRight:
                rotationAngle = 270
            default:
                rotationAngle = 0
            }
            
            // iOS 17+ 에서는 videoRotationAngle 사용
            if #available(iOS 17.0, *) {
                connection.videoRotationAngle = rotationAngle
            } else {
                // iOS 17 미만에서는 기존 videoOrientation 사용
                switch windowScene.interfaceOrientation {
                case .portrait:
                    connection.videoOrientation = .portrait
                case .portraitUpsideDown:
                    connection.videoOrientation = .portraitUpsideDown
                case .landscapeLeft:
                    connection.videoOrientation = .landscapeLeft
                case .landscapeRight:
                    connection.videoOrientation = .landscapeRight
                default:
                    connection.videoOrientation = .portrait
                }
            }
        }
    }
    
    private func updateMirroringForCurrentCamera() {
        
    }
    
    private func getCurrentCameraPosition() -> AVCaptureDevice.Position {
        guard let input = session.inputs.first as? AVCaptureDeviceInput else {
            return .unspecified
        }
        return input.device.position
    }
    
    private func getRotationAngleForCurrentOrientation() -> CGFloat {
        // 현재 인터페이스 방향을 기준으로 회전 각도 계산
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            switch windowScene.interfaceOrientation {
            case .portrait:
                return 0
            case .portraitUpsideDown:
                return 180
            case .landscapeLeft:
                return 270  // landscapeLeft는 반시계방향이므로 270도
            case .landscapeRight:
                return 90   // landscapeRight는 시계방향이므로 90도
            default:
                return 0
            }
        }
        
        // 백업으로 디바이스 방향 사용
        let orientation = UIDevice.current.orientation
        switch orientation {
        case .portrait:
            return 0
        case .portraitUpsideDown:
            return 180
        case .landscapeLeft:
            return 270
        case .landscapeRight:
            return 90
        default:
            return 0
        }
    }
    
    // 세션이 변경될 때 회전 코디네이터를 다시 설정하는 메서드
    func updateRotationCoordinator() {
        setupRotationCoordinator()
        updateVideoOrientation()
        updateMirroringForCurrentCamera()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
