# MyFourCut 
![Swift](https://img.shields.io/badge/Swift-5.9-F05138?logo=swift)
![Platform](https://img.shields.io/badge/Platforms-iOS%2018.0+-007AFF?logo=apple)

MyFourCut은 나만의 포토부스를 손안에 담은 iOS 애플리케이션으로, 셀카 촬영부터 꾸미기, 저장까지 한 번에 즐길 수 있는 디지털 인생네컷 경험을 제공합니다.

## 개요

- 프로젝트 이름: MyFourCut
- 개발 언어: Swift
- 개발 프레임워크: SwiftUI, PhotosUI, AVFoundation, CoreImage

## 🌟 주요 기능

### 📸 카메라 기능
- **실시간 프리뷰**: AVFoundation을 이용해 카메라 프리뷰를 제공합니다.
- **사진 촬영**: 최대 4장의 사진을 찍고 찍은 사진을 바로 프레임 적용할 수 있습니다.

### 🎨 프레임 적용
- **이미지 선택**: 원하는 사진을 내 갤러리에서 찾아서 프레임을 적용시킬 수 있어요.
- **다양한 프레임 선택**: FrameImages.swift에 등록된 다양한 테마를 적용할 수 있습니다.
- **이미지 합성**: 촬영한 사진에 프레임을 자동으로 오버레이합니다.

### 🔗 QR코드 공유
- **QR 코드 변환**: 저장한 사진을 QR 코드로 변환합니다.
- **간편 공유**: QR코드를 통해 사진을 다른 사람과 빠르게 공유할 수 있습니다.

### 🚀 스타트 화면
- **심플한 시작**: 앱 실행 시 StartView를 통해 사용자에게 시작 안내를 제공합니다.

---

## 📱 핵심 기능

### 카메라 및 사진 처리
- AVFoundation 기반 카메라 세션 관리
- SwiftUI를 이용한 카메라 미리보기 인터페이스
- 촬영 후 프레임을 적용해 즉시 저장 가능

### QR 코드 생성
- CoreImage 프레임워크를 활용해 QR 코드 이미지 생성
- 프레임이 적용된 결과 이미지를 QR로 공유하는 독특한 흐름 제공

### 직관적인 사용자 흐름
- 심플하고 명확한 화면 이동 (Start → CameraView → Frame 선택 → 저장/공유)
- SwiftUI 기반으로 부드럽고 자연스러운 전환 효과 구현

---

## 🔧 기술적 구현

### 사용된 프레임워크
- **SwiftUI**: UI 구현
- **AVFoundation**: 카메라 기능 제어
- **CoreImage**: QR 코드 생성
- **UIKit**: 이미지 합성 처리 일부
- **PhotosUI**: 갤러리에서 사진 가져오기

### 주요 구성 요소
- `CameraView.swift`: 카메라 세션 및 촬영
- `ContentView.swift`: 프레임 선택 및 사진 합성
- `FrameImages.swift`: 프레임 리소스 정의
- `QRShare.swift`: QR 코드 생성 및 공유
- `StartView.swift`: 시작 화면 제공
- `ContentViewTestCode.swift`: ContentView 기능 테스트 코드

### 기타 기능
- 사진 촬영 후 앨범 저장
- 저장된 이미지를 QR 코드로 변환하여 링크처럼 공유
---


## 🚀 시작하기

### 요구 사항
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

### 설치 및 실행
1. 레포지토리를 클론합니다.
    ```bash
    git clone https://github.com/your-username/FrameSnap.git
    ```
2. Xcode로 프로젝트를 열고 빌드합니다.
3. 카메라 사용 및 사진 저장을 위해 Info.plist에 다음 권한을 추가하세요.
    ```xml
    <key>NSCameraUsageDescription</key>
    <string>이 앱은 사진 촬영을 위해 카메라 접근을 요청합니다.</string>
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>이 앱은 촬영한 사진을 저장하기 위해 사진 라이브러리 접근을 요청합니다.</string>
    ```

---

## 🔮 향후 개선 사항
- 프레임 추가 커스터마이징 기능 (사용자 프레임 업로드)
- 실시간 AR 프레임 미리보기
- QR 코드 스캔 기능 추가 (FrameSnap 앱으로 직접 열기)
- 촬영한 사진 편집(크롭, 회전) 기능 추가
- SNS 공유 기능 연동 (Instagram, KakaoTalk 등)

---

## 느낀 점과 개선할 점

- **Simple is Best**: 사용자가 복잡한 편집 없이 빠르게 결과를 얻을 수 있도록 간결한 UX를 유지했습니다.
- **카메라 퍼포먼스 최적화 필요성**: AVFoundation 세션 초기화 속도를 더 빠르게 개선할 여지가 있습니다.
- **SwiftUI와 UIKit 조합**: SwiftUI 기반이지만 UIKit을 함께 사용하는 복합 구조에서 관리 포인트를 분리하여 더 체계적인 구조로 개선하고 싶습니다.

---
