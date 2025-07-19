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
    private var input: AVCaptureDeviceInput?
    private let output = AVCapturePhotoOutput()
    private var photoCompletion: ((UIImage) -> Void)?
    
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
                
                // 회전 지원 설정
                if let connection = output.connection(with: .video) {
                    if connection.isVideoRotationAngleSupported(0) {
                        connection.videoRotationAngle = 0
                    }
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
        
        // 현재 디바이스 방향에 따라 사진 방향 설정
        if let connection = output.connection(with: .video) {
            updatePhotoOrientation(connection: connection)
        }
        
        output.capturePhoto(with: settings, delegate: self)
    }
    
    private func updatePhotoOrientation(connection: AVCaptureConnection) {
        let rotationAngle = getRotationAngleForCurrentOrientation()
        if connection.isVideoRotationAngleSupported(rotationAngle) {
            connection.videoRotationAngle = rotationAngle
        }
    }
    
    private func getRotationAngleForCurrentOrientation() -> CGFloat {
        let orientation = UIDevice.current.orientation
        
        switch orientation {
        case .portrait:
            return 0
        case .portraitUpsideDown:
            return 180
        case .landscapeLeft:
            return 90
        case .landscapeRight:
            return -90
        default:
            // 알 수 없는 방향일 때는 인터페이스 방향을 기준으로 설정
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                switch windowScene.interfaceOrientation {
                case .portrait:
                    return 0
                case .portraitUpsideDown:
                    return 180
                case .landscapeLeft:
                    return -90
                case .landscapeRight:
                    return 90
                default:
                    return 0
                }
            } else {
                return 0
            }
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(),
           let image = UIImage(data: imageData) {
            Task { @MainActor in
                self.photoCompletion?(image)
            }
        }
    }
}
