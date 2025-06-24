//
//  CameraConfiguration.swift
//  MyFourCut
//
//  Created by 조영민 on 6/24/25.
//

import AVFoundation

struct CameraConfiguration {
    let sessionPreset: AVCaptureSession.Preset
    let defaultPosition: AVCaptureDevice.Position
    let photoSettings: AVCapturePhotoSettings
    
    static let `default` = CameraConfiguration(
        sessionPreset: .photo,
        defaultPosition: .front,
        photoSettings: AVCapturePhotoSettings()
    )
}
