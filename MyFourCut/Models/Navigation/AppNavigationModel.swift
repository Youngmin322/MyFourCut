//
//  AppNavigationModel.swift
//  MyFourCut
//
//  Created by 조영민 on 6/24/25.
//

import Foundation

enum NavigationDestination {
    case camera
    case content
    case frameEditor
}

struct AppNavigationModel {
    var currentDestination: NavigationDestination?
    var shouldShowCamera = false
    var shouldShowContent = false
    
    mutating func navigate(to destination: NavigationDestination) {
        currentDestination = destination
        
        switch destination {
        case .camera:
            shouldShowCamera = true
        case .content:
            shouldShowContent = true
        case .frameEditor:
            break
        }
    }
    
    mutating func reset() {
        currentDestination = nil
        shouldShowCamera = false
        shouldShowContent = false
    }
}
