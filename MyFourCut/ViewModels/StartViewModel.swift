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
    var selectedPath: Int? = nil
    var displayedImages: [Image?] = Array(repeating: nil, count: 4)
    
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
