//
//  CameraService.swift (최종 해결책)
//  MyFourCut
//

import AVFoundation
import UIKit

@Observable
class CameraService: NSObject {
    let session = AVCaptureSession()
    private var camera: AVCaptureDevice?
    var isUsingFrontCamera: Bool {
        return camera?.position == .front
    }
    private var input: AVCaptureDeviceInput?
    private let output = AVCapturePhotoOutput()
    private var photoCompletion: ((UIImage) -> Void)?
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    
    override init() {
        super.init()
        Task { await setupSession() }
    }
    
    func checkPermissions() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                await startSession()
            }
            return granted
        case .authorized:
            await startSession()
            return true
        default:
            return false
        }
    }
    
    func startSession() async {
        if !session.isRunning {
            await Task.detached {
                self.session.startRunning()
            }.value
        }
    }
    
    private func setupSession() async {
        await MainActor.run {
            do {
                session.beginConfiguration()
                
                if session.canSetSessionPreset(.photo) {
                    session.sessionPreset = .photo
                }
                
                // 전면 카메라를 기본으로 설정
                if let trueDepthCamera = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) {
                    camera = trueDepthCamera
                } else {
                    camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                }
                
                if let camera {
                    input = try AVCaptureDeviceInput(device: camera)
                    if session.canAddInput(input!) {
                        session.addInput(input!)
                    }
                    
                    if session.canAddOutput(output) {
                        session.addOutput(output)
                        
                        // 핵심: 출력 설정 최적화 - 기본값 그대로 두기
                        if let connection = output.connection(with: .video) {
                            // 미러링만 설정하고 회전은 건드리지 않음
                            connection.isVideoMirrored = (camera.position == .front)
                            print("초기 설정 - 미러링: \(connection.isVideoMirrored), 회전: \(connection.videoRotationAngle)°")
                        }
                    }
                    
                    setupRotationCoordinator()
                }
                
                session.commitConfiguration()
            } catch {
                print("카메라 설정 오류: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupRotationCoordinator() {
        if let camera = camera {
            rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: camera, previewLayer: nil)
        }
    }
    
    func switchCamera() {
        guard let currentInput = input else { return }
        let newPosition: AVCaptureDevice.Position = (camera?.position == .front) ? .back : .front
        
        Task {
            var newCamera: AVCaptureDevice?
            
            if newPosition == .front {
                if let trueDepthCamera = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) {
                    newCamera = trueDepthCamera
                } else {
                    newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                }
            } else {
                newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            }
            
            guard let selectedCamera = newCamera,
                  let newInput = try? AVCaptureDeviceInput(device: selectedCamera) else { return }
            
            await MainActor.run {
                session.beginConfiguration()
                session.removeInput(currentInput)
                
                if session.canAddInput(newInput) {
                    session.addInput(newInput)
                    input = newInput
                    camera = selectedCamera
                    
                    setupRotationCoordinator()
                    
                    // 미러링 및 방향 설정 업데이트
                    if let connection = output.connection(with: .video) {
                        connection.isVideoMirrored = (selectedCamera.position == .front)
                    }
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

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(),
           let image = UIImage(data: imageData) {
            
            // 가장 간단한 방법: 원본 이미지 그대로 사용
            Task { @MainActor in
                self.photoCompletion?(image)
            }
        }
    }
}
