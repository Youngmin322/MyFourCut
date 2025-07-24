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
class CameraViewModel {
    // Services
    private let cameraService = CameraService()
    private let hapticService = HapticService.shared
    
    // Models
    private var frameModel = FourCutFrameModel()
    private var countdownModel = CountdownModel()
    
    // Timer를 클래스로 래핑하여 참조 타입으로 관리
    private final class TimerContainer {
        var timer: Timer?
        
        func invalidate() {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private let timerContainer = TimerContainer()
    
    // Published Properties
    var shouldNavigateToContent = false
    var cameraAccessDenied = false
    var countDown: Int = 5
    
    // Computed Properties
    var displayedImages: [Image?] {
        frameModel.displayedImages
    }
    
    var isCountingDown: Bool {
        countdownModel.isActive
    }
    
    var photoCount: Int {
        frameModel.filledCount
    }
    
    var session: AVCaptureSession {
        cameraService.session
    }
    
    // MARK: - Public Methods
    
    func checkCameraAccess() async {
        let hasPermission = await cameraService.checkPermissions()
        if hasPermission {
            // 권한이 허용되었으면 카메라 세션을 명시적으로 시작
            await cameraService.startSession()
            startAutoCapture()
        } else {
            cameraAccessDenied = true
        }
    }
    
    func switchCamera() {
        hapticService.impact(.medium)
        cameraService.switchCamera()
    }
    
    func capturePhoto() {
        hapticService.impact(.medium)
        stopCurrentTimer()
        
        cameraService.capturePhoto { [weak self] image in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // CameraService에서 이미 방향 처리를 했으므로 그대로 사용
                let photo = PhotoModel(uiImage: image)
                if self.frameModel.addPhoto(photo) {
                    if !self.frameModel.isComplete {
                        self.scheduleNextPhoto()
                    }
                }
            }
        }
    }
    
    func resetImages() {
        stopCurrentTimer()
        frameModel.reset()
        countdownModel.reset()
        countDown = countdownModel.currentCount
    }
    
    func startCountdownAndCapture() {
        if frameModel.isComplete { return }
        stopCurrentTimer()
        startCountdownTimer(isManual: true)
    }
    
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    // MARK: - Private Methods
    
    private func startAutoCapture() {
        frameModel.reset()
        scheduleNextPhoto()
    }
    
    private func stopCurrentTimer() {
        timerContainer.invalidate()
        countdownModel.stop()
    }
    
    private func scheduleNextPhoto() {
        if frameModel.isComplete { return }
        
        stopCurrentTimer()
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            try? await Task.sleep(nanoseconds: 500_000_000)
            if !self.frameModel.isComplete {
                self.startCountdownTimer(isManual: false)
            }
        }
    }
    
    private func startCountdownTimer(isManual: Bool) {
        countdownModel.reset()
        countdownModel.start()
        countDown = countdownModel.currentCount
        
        // weak self를 사용하여 순환 참조 방지
        timerContainer.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            Task { @MainActor [weak self] in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                if self.countdownModel.tick() {
                    timer.invalidate()
                    self.timerContainer.timer = nil
                    self.countDown = 0
                    self.capturePhotoAuto(isManual: isManual)
                } else {
                    self.countDown = self.countdownModel.currentCount
                }
            }
        }
    }
    
    private func capturePhotoAuto(isManual: Bool) {
        hapticService.impact(.medium)
        cameraService.capturePhoto { [weak self] image in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // CameraService에서 이미 방향 처리를 했으므로 그대로 사용
                let photo = PhotoModel(uiImage: image)
                if self.frameModel.addPhoto(photo) {
                    if !isManual && !self.frameModel.isComplete {
                        self.scheduleNextPhoto()
                    }
                }
            }
        }
    }
    
    // deinit에서 Timer 정리
    deinit {
        timerContainer.invalidate()
    }
}
