//
//  CustomFrameService.swift
//  MyFourCut
//
//  Created by 조영민 on 7/16/25.
//

import SwiftUI
import Photos
import SwiftData

@MainActor
class CustomFrameService: ObservableObject {
    static let shared = CustomFrameService()
    
    @Published var customFrames: [BackgroundModel] = []
    private var modelContext: ModelContext?
    
    private init() {}
    
    // ModelContext 설정 (앱 시작시 호출)
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadCustomFrames()
    }
    
    func addCustomFrame(from asset: PHAsset, displayName: String) async {
        guard let image = await PhotoLibraryService.shared.loadImage(
            from: asset,
            targetSize: CGSize(width: 300, height: 500)
        ),
              let imageData = image.jpegData(compressionQuality: 0.8),
              let modelContext = modelContext else { return }
        
        // SwiftData 모델 생성
        let customFrame = CustomFrame(
            id: UUID().uuidString,
            displayName: displayName,
            imageData: imageData
        )
        
        // SwiftData에 저장
        modelContext.insert(customFrame)
        
        do {
            try modelContext.save()
            
            // BackgroundModel로 변환하여 배열에 추가
            if let backgroundModel = customFrame.toBackgroundModel() {
                customFrames.append(backgroundModel)
            }
        } catch {
            print("커스텀 프레임 저장 실패: \(error)")
        }
    }
    
    func removeCustomFrame(_ background: BackgroundModel) {
        guard let modelContext = modelContext else { return }
        
        // 모든 CustomFrame을 가져온 후 필터링 (Predicate 에러 회피)
        let descriptor = FetchDescriptor<CustomFrame>()
        
        do {
            let allFrames = try modelContext.fetch(descriptor)
            let framesToDelete = allFrames.filter { $0.id == background.id }
            
            for frame in framesToDelete {
                modelContext.delete(frame)
            }
            try modelContext.save()
            
            // 메모리에서도 삭제
            customFrames.removeAll { $0.id == background.id }
        } catch {
            print("커스텀 프레임 삭제 실패: \(error)")
        }
    }
    
    private func loadCustomFrames() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<CustomFrame>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        
        do {
            let frames = try modelContext.fetch(descriptor)
            customFrames = frames.compactMap { $0.toBackgroundModel() }
        } catch {
            print("커스텀 프레임 로드 실패: \(error)")
        }
    }
}
