import SwiftUI
import AVFoundation

/// 카메라 화면을 표시하는 뷰
struct CameraView: View {
    @Bindable private var camera = CameraModel() // 카메라 모델 (Observable)
    @Binding var displayedImages: [Image?] // 찍은 사진을 저장할 배열 (최대 4개)
    @Environment(\.dismiss) var dismiss // 현재 뷰를 닫는 기능

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
                                displayedImages = newImages  // 바인딩 업데이트

                                // 사진 4장 다 찍었으면 뷰 닫기
                                if !displayedImages.contains(where: { $0 == nil }) {
                                    dismiss()
                                }
                            }
                        }
                    }
                    label: {
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
        // 화면이 나타날 때 카메라 권한 확인
        .task {
            await camera.checkPermissions()
        }
        .onDisappear {
            displayedImages = Array(repeating: nil, count: 4) // 배열 초기화
        }
    }
}

// 카메라 프리뷰 (UIKit 사용)
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

// 카메라 모델 (카메라 동작을 관리하는 클래스)
@Observable
class CameraModel: NSObject {  // NSObject 상속 추가
    let session = AVCaptureSession() // 카메라 세션
    private var camera: AVCaptureDevice? // 현재 사용 중인 카메라
    private var input: AVCaptureDeviceInput? // 카메라 입력
    private let output = AVCapturePhotoOutput() // 사진 출력
    private var photoCompletion: ((UIImage) -> Void)? // 촬영 후 콜백 함수

    override init() {
        super.init()   // NSObject의 초기화 메서드 호출
        Task { await setupSession() }
    }
    
    /// 카메라 권한을 확인하고 요청하는 함수
    func checkPermissions() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            // 권한이 아직 결정되지 않은 경우
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                await startSession() // 권한 승인 시 카메라 세션 시작
                print("권한이 승인되었습니다.")
            } else {
                // 권한 거부됨
                print("사용자가 카메라 접근을 거부했습니다.")
            }
            
        case .restricted:
            // 권한이 제한된 경우
            print("카메라 접근이 제한되었습니다.")
            
        case .authorized:
            // 권한이 이미 승인된 경우
            await startSession() // 카메라 세션 시작
            print("카메라 세션이 시작되었습니다.")
            
        default:
            // 권한이 거부된 경우
            print("권한이 거부되었습니다.")
        }
    }

    /// 카메라 세션을 시작하는 함수
    private func startSession() async {
        if !session.isRunning {
            // Task.detached를 사용하여 백그라운드에서 실행
            await Task.detached {
                self.session.startRunning()
            }.value
        }
    }

    /// 카메라 세션을 설정하는 함수
    private func setupSession() async {
        do {
            session.beginConfiguration()
            
            // 기본 후면 카메라 설정
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

    /// 카메라 전환 함수 (후면, 전면)
    func switchCamera() {
        guard let currentInput = input else { return }
        let newPosition: AVCaptureDevice.Position = (camera?.position == .back) ? .front : .back
        
        Task {
            // 새로운 카메라 찾기
            guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newCamera) else { return }
            
            // 기존 입력 제거 후 새 입력 추가
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

    /// 사진 촬영 함수
    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        photoCompletion = completion
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
        print("못된 것")
    }
}

// 사진 촬영 후 데이터 처리
extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(),
           let image = UIImage(data: imageData) {
            Task { @MainActor in
                self.photoCompletion?(image) // 촬영된 이미지를 콜백으로 전달
            }
        }
    }
}

#Preview {
    CameraView(displayedImages: .constant([nil, nil, nil, nil]))
}
