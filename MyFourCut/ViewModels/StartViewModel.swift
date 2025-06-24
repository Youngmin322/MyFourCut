//
//  StartViewModel.swift
//  MyFourCut
//
//  Created by 조영민 on 6/24/25.
//

import SwiftUI

@MainActor
class StartViewModel {
    var displayedImages: [Image?] = []
    private var navigationModel = AppNavigationModel()
    private var frameModel = FourCutFrameModel()
    
    var selectedPath: Int? {
        get {
            switch navigationModel.currentDestination {
            case .camera: return 1
            case .content: return 2
            default: return nil
            }
        }
        set {
            if let value = newValue {
                switch value {
                case 1: navigationModel.navigate(to: .camera)
                case 2: navigationModel.navigate(to: .content)
                default: navigationModel.reset()
                }
            } else {
                navigationModel.reset()
            }
        }
    }
    
    func navigateToCamera() {
        selectedPath = 1
    }
    
    func navigateToContent() {
        selectedPath = 2
    }
    
    func resetSelection() {
        selectedPath = nil
    }
}
