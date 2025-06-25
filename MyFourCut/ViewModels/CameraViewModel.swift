//
//  CameraViewModel.swift
//  MyFourCut
//
//  Created by 조영민 on 6/24/25.
//

import SwiftUI
import UIKit
import AVFoundation

@Observable
class CameraViewModel: NSObject {
    private var frameModel = FourCutFrameModel()
    private var countdownModel = CountdownModel()
    private let cameraModel = CameraModel()
    
    // 타이머 관리를 위한 프로퍼티 추가
    private var currentTimer: Timer?
    
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
    
    // 수동 촬영 - 타이머 정리 후 즉시 촬영
    func capturePhoto() {
        playHaptic(style: .medium)
        
        // 진행 중인 타이머가 있다면 정리
        stopCurrentTimer()
        
        cameraModel.capturePhoto { [weak self] image in
            guard let self = self else { return }
            Task { @MainActor in
                let photo = PhotoModel(uiImage: image)
                if self.frameModel.addPhoto(photo) {
                    // 아직 사진이 더 필요하다면 자동 촬영 재시작
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
    
    func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    private func startAutoCapture() {
        frameModel.reset()
        scheduleNextPhoto()
    }
    
    // 수동 촬영을 위한 카운트다운 시작
    func startCountdownAndCapture() {
        if frameModel.isComplete { return }
        
        stopCurrentTimer() // 기존 타이머 정리
        startCountdownTimer(isManual: true)
    }
    
    // 타이머 정리 함수
    private func stopCurrentTimer() {
        currentTimer?.invalidate()
        currentTimer = nil
        countdownModel.stop()
    }
    
    // 다음 사진을 위한 카운트다운 예약
    private func scheduleNextPhoto() {
        if frameModel.isComplete { return }
        
        stopCurrentTimer()
        
        // 짧은 딜레이 후 카운트다운 시작 (자연스러운 전환을 위해)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기
            if !self.frameModel.isComplete {
                self.startCountdownTimer(isManual: false)
            }
        }
    }
    
    // 통합된 카운트다운 타이머
    private func startCountdownTimer(isManual: Bool) {
        countdownModel.reset()
        countdownModel.start()
        countDown = countdownModel.currentCount
        
        currentTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            Task { @MainActor in
                if self.countdownModel.tick() {
                    // 카운트다운 완료
                    timer.invalidate()
                    self.currentTimer = nil
                    self.countDown = 0
                    self.capturePhotoAuto(isManual: isManual)
                } else {
                    self.countDown = self.countdownModel.currentCount
                }
            }
        }
    }
    
    private func capturePhotoAuto(isManual: Bool) {
        playHaptic(style: .medium)
        cameraModel.capturePhoto { [weak self] image in
            guard let self = self else { return }
            Task { @MainActor in
                let photo = PhotoModel(uiImage: image)
                if self.frameModel.addPhoto(photo) {
                    // 수동 촬영이 아니고 아직 사진이 더 필요하다면 다음 촬영 예약
                    if !isManual && !self.frameModel.isComplete {
                        self.scheduleNextPhoto()
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
    
    deinit {
        stopCurrentTimer()
    }
}
