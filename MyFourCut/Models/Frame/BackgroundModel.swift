//
//  BackgroundModel.swift
//  MyFourCut
//
//  Created by 조영민 on 6/24/25.
//

import Foundation
import UIKit

struct BackgroundModel: Identifiable, Equatable {
    let id: String
    let imageName: String?  // 기본 번들 이미지용
    let displayName: String
    let customImage: UIImage?  // 사용자 커스텀 이미지용
    let isCustom: Bool
    
    // 기존 생성자
    init(id: String, imageName: String, displayName: String) {
        self.id = id
        self.imageName = imageName
        self.displayName = displayName
        self.customImage = nil
        self.isCustom = false
    }
    
    // 커스텀 이미지용 생성자
    init(id: String, customImage: UIImage, displayName: String) {
        self.id = id
        self.imageName = nil
        self.displayName = displayName
        self.customImage = customImage
        self.isCustom = true
    }
    
    // Equatable 프로토콜 준수
    static func == (lhs: BackgroundModel, rhs: BackgroundModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    static let defaultBackgrounds = [
        BackgroundModel(id: "bg0", imageName: "bg0", displayName: "기본"),
        BackgroundModel(id: "bg1", imageName: "bg1", displayName: "배경1"),
        BackgroundModel(id: "bg2", imageName: "bg2", displayName: "배경2"),
        BackgroundModel(id: "bg3", imageName: "bg3", displayName: "배경3"),
        BackgroundModel(id: "bg4", imageName: "bg4", displayName: "배경4"),
        BackgroundModel(id: "bg5", imageName: "bg5", displayName: "배경5")
    ]
}
