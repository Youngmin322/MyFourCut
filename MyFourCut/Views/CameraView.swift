import SwiftUI
import UIKit
import AVFoundation

struct CameraView: View {
    @Bindable private var camera = CameraModel()
    @Binding var displayedImages: [Image?]
    @Environment(\.dismiss) var dismiss
    @State private var shouldNavigateToContent = false
    @State private var countDown = 5
    @State private var isCountingDown = false
    @State private var photoCount = 0
    @State private var cameraAccessDenied = false
    
    var body: some View {
        ZStack {
            // 카메라 미리보기 화면
            CameraPreview(session: camera.session)
                .ignoresSafeArea()
            
            if isCountingDown {
                Text("\(countDown)")
                    .font(.system(size: 100, weight: .bold))
                    .bold()
                    .foregroundColor(.red)
                    .padding()
                    .transition(.scale)
            }
            
            VStack {
                Spacer()
                // 찍은 사진을 보여주는 미리보기 (최대 4장)
                HStack {
                    ForEach(0..<4) { index in
                        if let image = displayedImages[index] {
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
                
                // 카메라 컨트롤 버튼 (닫기, 촬영, 전환)
                HStack(spacing: 60) {
                    // 닫기 버튼
                    Button {
                        playHaptic(style: .medium)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    
                    // 사진 촬영 버튼
                    Button {
                        playHaptic(style: .medium)
                        camera.capturePhoto { image in
                            // 첫 번째 비어 있는 공간에 사진 추가
                            if let firstEmpty = displayedImages.firstIndex(where: { $0 == nil }) {
                                var newImages = displayedImages
                                newImages[firstEmpty] = Image(uiImage: image)
                                displayedImages = newImages
                            }
                            countDown = 5
                        }
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
                        playHaptic(style: .medium)
                        camera.switchCamera()
                    } label: {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .task {
            await checkCameraAccess()
        }
        .onDisappear {
            displayedImages = Array(repeating: nil, count: 4)
            isCountingDown = false
            countDown = 0
        }
        .navigationDestination(isPresented: $shouldNavigateToContent) {
            ContentView(initialImages: displayedImages)
        }
        .onChange(of: displayedImages) { _, newImages in
            if !newImages.contains(where: { $0 == nil }) {
                shouldNavigateToContent = true
            }
        }
        .overlay {
            if cameraAccessDenied {
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
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString),
                               UIApplication.shared.canOpenURL(settingsURL) {
                                UIApplication.shared.open(settingsURL)
                            }
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
    }
    
    func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    private func startAutoCapture() {
        photoCount = 0
        captureNextPhoto()
    }
    
    private func captureNextPhoto() {
        if photoCount >= 4 { return } // 사진 4장을 다 찍으면 종료
        
        isCountingDown = true
        countDown = 5
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if !isCountingDown {
                timer.invalidate()
                return
            }
            if countDown > 1 {
                countDown -= 1
            } else {
                timer.invalidate()
                isCountingDown = false
                capturePhoto()
            }
        }
    }
    
    private func capturePhoto() {
        playHaptic(style: .medium)
        camera.capturePhoto { image in
            if let firstEmpty = displayedImages.firstIndex(where: { $0 == nil }) {
                var newImages = displayedImages
                newImages[firstEmpty] = Image(uiImage: image)
                displayedImages = newImages
                photoCount += 1
                
                if photoCount < 4 {
                    captureNextPhoto()
                }
            }
        }
    }
    
    private func checkCameraAccess() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                await camera.checkPermissions()
                startAutoCapture()
            } else {
                cameraAccessDenied = true
            }
        case .authorized:
            await camera.checkPermissions()
            startAutoCapture()
        default:
            cameraAccessDenied = true
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

@Observable
class CameraModel: NSObject {
    let session = AVCaptureSession()
    private var camera: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    private let output = AVCapturePhotoOutput()
    private var photoCompletion: ((UIImage) -> Void)?
    
    override init() {
        super.init()
        Task { await setupSession() }
    }
    
    func checkPermissions() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                await startSession()
            }
        case .restricted:
            print("카메라 접근이 제한되었습니다.")
        case .authorized:
            await startSession()
        default:
            print("권한이 거부되었습니다.")
        }
    }
    
    private func startSession() async {
        if !session.isRunning {
            await Task.detached {
                self.session.startRunning()
            }.value
        }
    }
    
    private func setupSession() async {
        do {
            session.beginConfiguration()
            
            camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            
            if let camera {
                input = try AVCaptureDeviceInput(device: camera)
                if session.canAddInput(input!) {
                    session.addInput(input!)
                }
                
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }
            }
            
            session.commitConfiguration()
        } catch {
            print("카메라 설정 오류: \(error.localizedDescription)")
        }
    }
    
    func switchCamera() {
        guard let currentInput = input else { return }
        let newPosition: AVCaptureDevice.Position = (camera?.position == .front) ? .back : .front
        
        Task {
            guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newCamera) else { return }
            
            await MainActor.run {
                session.beginConfiguration()
                session.removeInput(currentInput)
                
                if session.canAddInput(newInput) {
                    session.addInput(newInput)
                    input = newInput
                    camera = newCamera
                }
                
                session.commitConfiguration()
            }
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        photoCompletion = completion
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(),
           let image = UIImage(data: imageData) {
            Task { @MainActor in
                self.photoCompletion?(image)
            }
        }
    }
}
