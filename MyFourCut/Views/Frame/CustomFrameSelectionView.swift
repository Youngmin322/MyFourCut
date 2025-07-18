//
//  CustomFrameSelectionView.swift
//  MyFourCut
//
//  Created by 조영민 on 7/18/25.
//

import SwiftUI
import Photos

struct CustomFrameSelectionView: View {
    @Binding var isPresented: Bool
    @State private var selectedAsset: PHAsset?
    @State private var frameName: String = ""
    @State private var showingNameInput = false
    let onFrameAdded: (BackgroundModel) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                // 갤러리 그리드 (PhotoSelectionView와 유사)
                // 선택된 이미지 미리보기
                // 이름 입력 필드
                // 추가 버튼
            }
            .navigationTitle("프레임 추가")
            .navigationBarItems(
                leading: Button("취소") { isPresented = false },
                trailing: Button("완료") { addCustomFrame() }
            )
        }
    }
    
    private func addCustomFrame() {
        // 선택된 이미지로 커스텀 프레임 생성
    }
}
