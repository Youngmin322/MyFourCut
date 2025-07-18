//
//  CustomFrame.swift
//  MyFourCut
//
//  Created by 조영민 on 7/18/25.
//

import Foundation
import SwiftData
import UIKit

@Model
final class CustomFrame {
    var id: String
    var displayName: String
    var imageData: Data
    var createdDate: Date
    
    init(id: String, displayName: String, imageData: Data) {
        self.id = id
        self.displayName = displayName
        self.imageData = imageData
        self.createdDate = Date()
    }
    
    // UIImage로 변환하는 편의 프로퍼티
    var uiImage: UIImage? {
        return UIImage(data: imageData)
    }
    
    // BackgroundModel로 변환하는 메서드
    func toBackgroundModel() -> BackgroundModel? {
        guard let uiImage = self.uiImage else { return nil }
        return BackgroundModel(
            id: self.id,
            customImage: uiImage,
            displayName: self.displayName
        )
    }
}
