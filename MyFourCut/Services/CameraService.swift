//
//  CameraService.swift
//  MyFourCut
//
//  Created by 조영민 on 7/14/25.
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
                    }
                    
                    // 회전 코디네이터 설정
                    setupRotationCoordinator()
                }
                
                session.commitConfiguration()
                
                // commitConfiguration 후에 방향 설정
                if let connection = output.connection(with: .video) {
                    updatePhotoOrientation(connection: connection)
                }
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
                // 전면: TrueDepth 카메라 우선, 없으면 일반 전면 카메라
                if let trueDepthCamera = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) {
                    newCamera = trueDepthCamera
                } else {
                    newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                }
            } else {
                // 후면: 일반 후면 카메라
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
                    
                    // 새 카메라로 회전 코디네이터 업데이트
                    setupRotationCoordinator()
                    
                    // 카메라 전환 후 방향 다시 설정
                    if let connection = output.connection(with: .video) {
                        updatePhotoOrientation(connection: connection)
                    }
                }
                
                session.commitConfiguration()
            }
        }
    }

    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        photoCompletion = completion
        let settings = AVCapturePhotoSettings()
        
        // 현재 디바이스 방향에 따라 사진 방향 설정
        if let connection = output.connection(with: .video) {
            // 메인 스레드에서 방향 업데이트
            Task { @MainActor in
                self.updatePhotoOrientation(connection: connection)
                
                // 방향 설정 후 사진 촬영
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.output.capturePhoto(with: settings, delegate: self)
                }
            }
        } else {
            output.capturePhoto(with: settings, delegate: self)
        }
    }

    private func updatePhotoOrientation(connection: AVCaptureConnection) {
        // 메인 스레드에서 UI API 호출 보장
        Task { @MainActor in
            // 현재 인터페이스 방향에 맞게 정확한 방향 설정
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let orientation: AVCaptureVideoOrientation
                switch windowScene.interfaceOrientation {
                case .portrait:
                    orientation = .portrait
                case .portraitUpsideDown:
                    orientation = .portraitUpsideDown
                case .landscapeLeft:
                    orientation = .landscapeLeft
                case .landscapeRight:
                    orientation = .landscapeRight
                default:
                    orientation = .portrait
                }
                
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = orientation
                }
            }
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(),
           let image = UIImage(data: imageData) {
            
            // 이미지 방향을 올바르게 수정 (강제 회전 제거)
            let correctedImage = correctImageOrientation(image)
            
            Task { @MainActor in
                self.photoCompletion?(correctedImage)
            }
        }
    }

    // 이미지 방향 수정 메서드 (강제 회전 제거)
    private func correctImageOrientation(_ image: UIImage) -> UIImage {
        // 이미 올바른 방향이면 그대로 반환
        guard image.imageOrientation != .up else {
            return image
        }

        // 방향 정규화만 수행 (강제 회전 제거)
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let fixedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return fixedImage ?? image
    }
}
