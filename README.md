# KaraokeBooks
노래방 책자 어플

<img width="1306" alt="스크린샷 2024-12-20 23 16 13" src="https://github.com/user-attachments/assets/6727ebd6-eb13-4664-aee1-6ebdfae06ea1" />

## 프로젝트 설명
> 개발 인원: 1명 (iOS)
> 
> 개발 기간: 2023년 2월 (최초 개발기간 2주, 현재까지 서비스중)

- TJ, KY 노래방의 곡 정보, 인기차트 등을 검색하고 애창곡을 저장할 수 있는 어플
- 앱스토어에 출시 후 지속적으로 관리 중
- [앱스토어](https://apps.apple.com/kr/app/%EB%85%B8%EB%9E%98%EB%B0%A9book/id1672848960)

## 사용 기술
- ~~MVP Architecture~~ -> ReactorKit + MVVM

  > ViewController에 책임을 나누기 위해 MVP 아키텍처 사용
    View와 Presenter가 1:1 대응이 되게 구성했었음.
  > 
  > (2024.12) MVP에서 ReactorKit을 사용해 MVVM으로 구조 변경
  > 
  > ReactorKit을 사용하니 상태관리가 편했고 구조화 되어 있어서 빠르게 작업을 완료할 수 있었다.
  > 
  > RxSwift을 사용해보며 Operation들을 사용해 더 간소화 된 코드를 만들 수 있었다.

- UIKit, SnapKit
  
  > Storyboard를 사용하지 않고 SnapKit 라이브러리를 사용해 뷰 구성 (Code Base UI)
- Swift Concurrency (async/await)
  
  > 노래방 곡 정보등의 데이터를 서버에서 가져올 때 비동기 API 통신 구현
- CoreData

  > 유저가 애창곡을 저장했을 때 데이터를 저장하기 위해 구현
  > 
  > 기존에는 UserDefaults에 저장하여 관리했지만, 업데이트 후 앱 실행시 UserDefaults에 있는 데이터를 CoreData로 마이그레이션 후 CoreData만 사용
- RxSwift

  > RxSwift를 도입하고 기존 서비스(CoreData, API통신) 코드는 그대로 두고 Rx용 custom extension으로 기존 메서드를 감싸 Single타입을 반환하도록 변경


## 소스 폴더 구조

- `App`: 앱 시작과 환경 구성
- `Data`: API, 차트 캐시, 로컬 저장소
- `Domain`: 곡·검색 모델과 Core Data 모델
- `Presentation/<화면>`: 화면별 ViewController와 Reactor. 화면 전용 뷰는 각 `Views`에 배치
- `Presentation/Shared/Ads`: 배너·네이티브·전면 광고
- `Presentation/Shared/SongList`: 공용 곡 목록, 페이저, 곡 셀과 표시 모델
- `Presentation/Shared/Controls`: 여러 화면에서 사용하는 컨트롤

파일을 이동할 때는 실제 폴더와 Xcode 그룹 경로를 함께 수정합니다.

## Preview

<img width="250" src="https://github.com/user-attachments/assets/8bc8d832-aed3-4299-9da9-53aba4d3d22d">

## 사용 라이브러리
- Alamofire
- SnapKit
- ReactorKit
- RxSwift

### API 
- https://api.manana.kr/karaoke
