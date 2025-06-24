//
//  CameraViewModel.swift
//  MyFourCut
//
//  Created by 조영민 on 6/24/25.
//

import SwiftUI
import UIKit
import AVFoundation

@MainActor
@Observable
class CameraViewModel: NSObject {
    var shouldNavigateToContent = false
    var countDown = 5
    var isCountingDown = false
    var photoCount = 0
    var cameraAccessDenied = false
    var displayedImages: [Image?] = Array(repeating: nil, count: 4)
    
    private let cameraModel = CameraModel()
    
    var session: AVCaptureSession {
        cameraModel.session
    }
    
    override init() {
        super.init()
        setupBindings()
    }
    
    private func setupBindings() {
        // CameraModel과의 바인딩 설정
    }
    
    func checkCameraAccess() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                await cameraModel.checkPermissions()
                startAutoCapture()
            } else {
                cameraAccessDenied = true
            }
        case .authorized:
            await cameraModel.checkPermissions()
            startAutoCapture()
        default:
            cameraAccessDenied = true
        }
    }
    
    func switchCamera() {
        playHaptic(style: .medium)
        cameraModel.switchCamera()
    }
    
    func capturePhoto() {
        playHaptic(style: .medium)
        cameraModel.capturePhoto { [weak self] image in
            guard let self = self else { return }
            Task { @MainActor in
                if let firstEmpty = self.displayedImages.firstIndex(where: { $0 == nil }) {
                    self.displayedImages[firstEmpty] = Image(uiImage: image)
                }
                self.countDown = 5
            }
        }
    }
    
    func resetImages() {
        displayedImages = Array(repeating: nil, count: 4)
        isCountingDown = false
        countDown = 0
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
        if photoCount >= 4 { return }
        
        isCountingDown = true
        countDown = 5
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            Task { @MainActor in
                if !self.isCountingDown {
                    timer.invalidate()
                    return
                }
                if self.countDown > 1 {
                    self.countDown -= 1
                } else {
                    timer.invalidate()
                    self.isCountingDown = false
                    self.capturePhotoAuto()
                }
            }
        }
    }
    
    private func capturePhotoAuto() {
        playHaptic(style: .medium)
        cameraModel.capturePhoto { [weak self] image in
            guard let self = self else { return }
            Task { @MainActor in
                if let firstEmpty = self.displayedImages.firstIndex(where: { $0 == nil }) {
                    self.displayedImages[firstEmpty] = Image(uiImage: image)
                    self.photoCount += 1
                    
                    if self.photoCount < 4 {
                        self.captureNextPhoto()
                    }
                }
            }
        }
    }
    
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}
