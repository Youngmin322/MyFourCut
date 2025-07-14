//
//  StartViewModel.swift
//  MyFourCut
//
//  Created by 조영민 on 6/24/25.
//

import SwiftUI

@MainActor
@Observable
class StartViewModel {
    var displayedImages: [Image?] = []
    var selectedPath: Int? = nil
    
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
