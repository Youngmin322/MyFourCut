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
    private var frameModel = FourCutFrameModel()
    private var countdownModel = CountdownModel()
    private let cameraModel = CameraModel()
    
    var shouldNavigateToContent = false
    var cameraAccessDenied = false
    var displayedImages: [Image?] {
        frameModel.displayedImages
    }
    
    var countDown: Int = 5
    
    var isCountingDown: Bool {
        countdownModel.isActive
    }
    
    var photoCount: Int {
        frameModel.filledCount
    }
    
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
                let photo = PhotoModel(uiImage: image)
                if self.frameModel.addPhoto(photo) {
                    self.countdownModel.reset()
                    self.countDown = self.countdownModel.currentCount
                }
            }
        }
    }
    
    func resetImages() {
        frameModel.reset()
        countdownModel.reset()
        countDown = countdownModel.currentCount
    }
    
    func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    private func startAutoCapture() {
        frameModel.reset()
        captureNextPhoto()
    }
    
    func startCountdownAndCapture() {
        if frameModel.isComplete { return }
        
        countdownModel.reset()
        countdownModel.start()
        countDown = countdownModel.currentCount
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            Task { @MainActor in
                if self.countdownModel.tick() {
                    self.countDown = self.countdownModel.currentCount
                    timer.invalidate()
                    self.capturePhotoAuto()
                } else {
                    self.countDown = self.countdownModel.currentCount
                }
            }
        }
    }
    
    private func captureNextPhoto() {
        if frameModel.isComplete { return }
        
        countdownModel.start()
        countDown = countdownModel.currentCount
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            Task { @MainActor in
                if !self.countdownModel.isActive {
                    timer.invalidate()
                    return
                }
                
                if self.countdownModel.tick() {
                    // 카운트다운 완료
                    timer.invalidate()
                    self.countDown = self.countdownModel.currentCount
                    self.capturePhotoAuto()
                } else {
                    self.countDown = self.countdownModel.currentCount
                }
            }
        }
    }
    
    private func capturePhotoAuto() {
        playHaptic(style: .medium)
        cameraModel.capturePhoto { [weak self] image in
            guard let self = self else { return }
            Task { @MainActor in
                let photo = PhotoModel(uiImage: image)
                if self.frameModel.addPhoto(photo) {
                    if !self.frameModel.isComplete {
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
