//
//  FilterType.swift
//  MyFourCut
//
//  Created by 조영민 on 7/14/25.
//

import SwiftUI

enum FilterType: CaseIterable {
    case none, blackWhite, sepia, vintage, cool, warm
    
    var name: String {
        switch self {
        case .none: return "원본"
        case .blackWhite: return "흑백"
        case .sepia: return "세피아"
        case .vintage: return "빈티지"
        case .cool: return "차가운"
        case .warm: return "따뜻한"
        }
    }
    
    var color: Color {
        switch self {
        case .none: return .white
        case .blackWhite: return .gray
        case .sepia: return Color(red: 0.7, green: 0.5, blue: 0.3)
        case .vintage: return Color(red: 0.8, green: 0.7, blue: 0.6)
        case .cool: return Color(red: 0.6, green: 0.8, blue: 1.0)
        case .warm: return Color(red: 1.0, green: 0.8, blue: 0.6)
        }
    }
}
