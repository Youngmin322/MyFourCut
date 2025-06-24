//
//  BackgroundModel.swift
//  MyFourCut
//
//  Created by 조영민 on 6/24/25.
//

import Foundation

struct BackgroundModel {
    let id: String
    let imageName: String
    let displayName: String
    
    static let defaultBackgrounds = [
        BackgroundModel(id: "bg0", imageName: "bg0", displayName: "기본"),
        BackgroundModel(id: "bg1", imageName: "bg1", displayName: "배경1"),
        BackgroundModel(id: "bg2", imageName: "bg2", displayName: "배경2"),
        BackgroundModel(id: "bg3", imageName: "bg3", displayName: "배경3"),
        BackgroundModel(id: "bg4", imageName: "bg4", displayName: "배경4"),
        BackgroundModel(id: "bg5", imageName: "bg5", displayName: "배경5")
    ]
}
