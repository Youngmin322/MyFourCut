import SwiftUI
import AVFoundation

struct CameraView: View {
    @Bindable private var camera = CameraModel()
    @Binding var displayedImages: [Image?]
    @Environment(\.dismiss) var dismiss
    @State private var shouldNavigateToContent = false
    
    var body: some View {
        ZStack {
            // 카메라 미리보기 화면
            CameraPreview(session: camera.session)
                .ignoresSafeArea()
            
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
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    
                    // 사진 촬영 버튼
                    Button {
                        camera.capturePhoto { image in
                            // 첫 번째 비어 있는 공간에 사진 추가
                            if let firstEmpty = displayedImages.firstIndex(where: { $0 == nil }) {
                                var newImages = displayedImages
                                newImages[firstEmpty] = Image(uiImage: image)
                                displayedImages = newImages
                            }
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
            await camera.checkPermissions()
        }
        .onDisappear {
            displayedImages = Array(repeating: nil, count: 4)
        }
        .navigationDestination(isPresented: $shouldNavigateToContent) {
            ContentView(initialImages: displayedImages)
        }
        .onChange(of: displayedImages) { _, newImages in
            if !newImages.contains(where: { $0 == nil }) {
                shouldNavigateToContent = true
            }
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
            
            camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            
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
        let newPosition: AVCaptureDevice.Position = (camera?.position == .back) ? .front : .back
        
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

#Preview {
    CameraView(displayedImages: .constant([nil, nil, nil, nil]))
}
