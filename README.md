# RunningLog

## 주요 기능

### 러닝 추적
- **위치 추적 및 러닝 기록 구성**: Kalman Filter 알고리즘을 적용한 GPS 노이즈 제거 및 정확도 향상
- **실시간 데이터**: 거리, 시간, 페이스, 칼로리 실시간 계산
- **백그라운드 추적**: 앱이 백그라운드에 있어도 연속적인 위치 추적
- **심박수 모니터링**: HealthKit을 통한 실시간 심박수 데이터 수집
- **경로 시각화**: MapKit을 활용한 러닝 경로 표시 및 속도별 색상 구분

### 날씨 정보
- **실시간 날씨**: OpenWeatherMap API를 통한 현재 날씨 정보
- **시간별 예보**: 3시간 단위 날씨 예보 제공
- **대기질 정보**: PM2.5, PM10 등 대기질 지수 제공
- **위치 기반**: GPS 위치에 따른 정확한 날씨 정보

### 데이터 관리
- **CoreData 저장**: 러닝 기록 CoreData 저장
- **HealthKit 연동**: HealthKit 통한 심박수 데이터
- **상세 기록**: 러닝 시간, 거리, 칼로리, 평균 페이스, 경로 정보 저장
- **기록 목록**: 과거 러닝 기록 조회 및 관리

### 위젯
- **홈 스크린 위젯**: 현재 러닝 상태를 홈 스크린에서 바로 확인
- **실시간 업데이트**: 러닝 중 위젯 데이터 자동 갱신
- **간편 제어**: 위젯에서 직접 러닝 시작/일시정지 가능

### 다국어 지원
- **3개 언어**: 한국어, 영어, 일본어 지원
- **로컬라이제이션**: 모든 UI 텍스트 및 메시지 현지화
- **지역 맞춤**: 날짜/시간 형식 등 지역별 표시 형식 지원

## 기술 스택

### 아키텍처
- **TCA (The Composable Architecture)**: TCA 기반의 단방향 아키텍처로 데이터 플로우 관리

### 프레임워크 & 라이브러리
- **SwiftUI**: 선언적 UI 프레임워크
- **MapKit**: 지도 및 위치 서비스
- **HealthKit**: 건강 데이터 통합
- **CoreData**: 로컬 데이터 저장
- **CoreLocation**: 위치 추적 및 지오코딩
- **WidgetKit**: 위젯 개발 프레임워크
- **Combine**: 반응형 프로그래밍

### 사용 기술
- **Kalman Filter**: GPS 신호 노이즈 제거 및 위치 정확도 개선
- **AsyncSequence**: 비동기 위치 업데이트 스트림
- **Background Location**: 백그라운드 위치 추적
- **App Groups**: 앱과 위젯 간 데이터 공유
- **Async/Await**: 모던 Swift 비동기 처리

### 외부 API
- **OpenWeatherMap API**: 날씨 정보 및 대기질 데이터
  - Current Weather API: 실시간 날씨
  - Forecast API: 시간별 예보
  - Air Pollution API: 대기질 정보

## 프로젝트 구조

```
RunningLog/
├── App/                          # 앱 진입점 및 설정
│   └── RunningLogApp.swift      # 메인 앱 클래스
├── Domain/                       # 도메인 레이어
│   ├── Entity/                  # 비즈니스 엔티티
│   │   ├── RunningSession.swift
│   │   ├── RunningRecord.swift
│   │   ├── WeatherData.swift
│   │   └── UserProfile.swift
│   ├── Repository/              # 리포지토리 인터페이스
│   └── Client/                  # 외부 서비스 클라이언트
├── Data/                        # 데이터 레이어
│   ├── Service/                 # 네트워킹 및 데이터 서비스
│   │   ├── NetworkService.swift
│   │   ├── DataTransferService.swift
│   │   └── LocationClientImpl.swift
│   ├── Router/                  # API 라우터
│   │   ├── WeatherRouter.swift
│   │   ├── WeatherForecastRouter.swift
│   │   └── WeatherNowRouter.swift
│   └── Repository/              # 리포지토리 구현
│       └── CoreDataRunningRecordRepository.swift
├── Present/                     # 프레젠테이션 레이어
│   ├── Tab/                     # 탭 네비게이션
│   ├── Running/                 # 러닝 추적 화면
│   │   ├── RunningView.swift
│   │   ├── RunningFeature.swift
│   │   ├── MapView.swift
│   │   └── MapKitView.swift
│   ├── Weather/                 # 날씨 화면
│   │   ├── WeatherView.swift
│   │   └── WeatherFeature.swift
│   ├── RunningRecordList/       # 기록 목록 화면
│   └── Component/               # 재사용 가능한 UI 컴포넌트
└── Utility/                     # 유틸리티
    ├── KalmanFilterManager.swift # GPS 필터링
    ├── Design.swift             # 디자인 시스템
    └── ViewModifier/            # 커스텀 뷰 모디파이어

RunningWidget/                   # 위젯 확장
├── RunningWidget.swift         # 위젯 메인
└── RunningWidgetBundle.swift   # 위젯 번들
```

## 주요 기술적 특징

### 1. Kalman Filter 기반 GPS 정확도 향상
```swift
final class DefaultKalmanFilterManager: KalmanFilterManagerProtocol {
    private let filter = KalmanFilter2D(processNoise: 1e-2, measurementNoise: 1e-3)
    private let maxHumanSpeed: CLLocationSpeed = 20.0 // m/s
    private let minSpeed: CLLocationSpeed = 0.3 // 0.3m/s(1km/h) 미만 무시
    
    func filter(location: CLLocation) -> CLLocation? {
        // 이상치 위치 제거 및 칼만 필터 적용
    }
}
```

### 2. TCA 기반 상태 관리
```swift
@Reducer
struct RunningFeature {
    @ObservableState
    struct State: Equatable {
        var session: RunningSession = .init()
        var pathLocations: [CLLocation] = []
        var isLoading = false
    }
    
    enum Action {
        case startRunning
        case stopRunning
        case updateLocation(CLLocation)
        case timerTick
    }
}
```

### 3. 백그라운드 위치 추적
- `UIBackgroundModes`: location 모드 활성화
- `allowsBackgroundLocationUpdates`: 백그라운드 위치 업데이트 허용
- `pausesLocationUpdatesAutomatically`: 자동 일시정지 비활성화

### 4. 위젯과 앱 간 데이터 공유
```swift
// App Groups를 통한 데이터 공유
let sharedDefaults = UserDefaults(suiteName: "group.den.RunningLog.shared")
sharedDefaults?.set(formattedTime, forKey: "time")
WidgetCenter.shared.reloadTimelines(ofKind: "RunningWidget")
```

## 시스템 요구사항

- **iOS**: 17.0 이상
- **Xcode**: 15.0 이상
- **Swift**: 5.9 이상
- **권한**: 위치, HealthKit, 백그라운드 위치 추적

### 5. 빌드 및 실행
- 물리 기기에서 실행 (시뮬레이터에서는 GPS 기능 제한)
- HealthKit 권한 허용 필요

---
