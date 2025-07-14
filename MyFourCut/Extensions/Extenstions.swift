//
//  Extenstions.swift
//  MyFourCut
//
//  Created by 조영민 on 7/14/25.
//

import SwiftUI
import UIKit

// MARK: - Image Extensions
extension Image {
    func asUIImage() -> UIImage? {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let uiImage = child.value as? UIImage {
                return uiImage
            }
        }
        return nil
    }
}

// MARK: - UIImage Extensions
extension UIImage {
    /// UIImage를 SwiftUI Image로 변환
    func asImage() -> Image {
        return Image(uiImage: self)
    }
    
    /// 이미지 크기 조정
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        self.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 이미지를 정사각형으로 크롭
    func cropped() -> UIImage? {
        let minDimension = min(size.width, size.height)
        let cropSize = CGSize(width: minDimension, height: minDimension)
        
        let x = (size.width - cropSize.width) / 2
        let y = (size.height - cropSize.height) / 2
        let cropRect = CGRect(x: x, y: y, width: cropSize.width, height: cropSize.height)
        
        guard let cgImage = self.cgImage?.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
    }
}

// MARK: - View Extensions
extension View {
    /// View를 UIImage로 변환 (iOS 16+)
    @MainActor
    func asUIImage(size: CGSize = CGSize(width: 300, height: 500)) -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
    
    /// 조건부 modifier 적용
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Color Extensions
extension Color {
    /// Hex 코드로 Color 생성
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// 색상을 UIColor로 변환
    func asUIColor() -> UIColor {
        return UIColor(self)
    }
}

// MARK: - Array Extensions
extension Array where Element == Image? {
    /// 배열에서 nil이 아닌 Image들만 반환
    var compactImages: [Image] {
        return self.compactMap { $0 }
    }
    
    /// 배열이 모두 채워져 있는지 확인
    var isComplete: Bool {
        return self.allSatisfy { $0 != nil }
    }
    
    /// 배열이 모두 비어있는지 확인
    var isEmpty: Bool {
        return self.allSatisfy { $0 == nil }
    }
    
    /// 채워진 항목의 개수
    var filledCount: Int {
        return self.compactMap { $0 }.count
    }
}

// MARK: - String Extensions
extension String {
    /// 문자열이 비어있지 않은지 확인
    var isNotEmpty: Bool {
        return !self.isEmpty
    }
    
    /// 문자열을 안전하게 트림
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - CGSize Extensions
extension CGSize {
    /// 정사각형 크기 생성
    static func square(_ side: CGFloat) -> CGSize {
        return CGSize(width: side, height: side)
    }
    
    /// 화면 크기에 맞는 비율로 조정
    func scaledToScreen() -> CGSize {
        let screenSize = UIScreen.main.bounds.size
        let scale = min(screenSize.width / width, screenSize.height / height)
        return CGSize(width: width * scale, height: height * scale)
    }
}

// MARK: - Bundle Extensions
extension Bundle {
    /// 번들에서 이미지 가져오기
    func image(named name: String) -> UIImage? {
        return UIImage(named: name, in: self, compatibleWith: nil)
    }
}
