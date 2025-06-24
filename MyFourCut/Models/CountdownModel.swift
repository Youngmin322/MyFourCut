//
//  CountdownModel.swift
//  MyFourCut
//
//  Created by 조영민 on 6/24/25.
//

import Foundation

struct CountdownModel {
    private(set) var currentCount: Int
    private(set) var isActive: Bool = false
    let initialCount: Int
    
    init(initialCount: Int = 5) {
        self.initialCount = initialCount
        self.currentCount = initialCount
    }
    
    mutating func start() {
        isActive = true
        currentCount = initialCount
    }
    
    mutating func tick() -> Bool {
        guard isActive && currentCount > 0 else { return false }
        currentCount -= 1
        if currentCount == 0 {
            isActive = false
            return true // 카운트다운 완료
        }
        return false
    }
    
    mutating func stop() {
        isActive = false
        currentCount = initialCount
    }
    
    mutating func reset() {
        currentCount = initialCount
        isActive = false
    }
}
