# 독독 안드로이드 앱 (에뮬레이터 실행용)

웹 프로토타입 `../Reading_app.html`을 그대로 띄우는 안드로이드 앱이에요.
빌드할 때마다 이 HTML이 앱 안으로 자동 복사되므로, 화면 수정은 지금처럼 HTML 파일 하나만 고치면 돼요.

## 에뮬레이터에서 실행하기
1. [Android Studio](https://developer.android.com/studio)를 설치하고 실행해요.
2. **Open** → 이 저장소의 `android` 폴더를 선택해요. (처음 열면 Gradle 동기화에 몇 분 걸려요.)
3. 오른쪽 위 **Device Manager**에서 가상 기기를 만들어요. 예: Pixel 7, Android 14(API 34).
4. 초록색 **Run ▶** 버튼을 누르면 에뮬레이터에 '독독' 앱이 설치되고 실행돼요.

## 앱에서 달라지는 점
- 휴대폰의 **뒤로가기**: 열린 팝업을 닫고, 없으면 앱 안의 '뒤로' 버튼처럼 동작해요. 첫 화면에서는 앱이 닫혀요.
- **프로필 사진 바꾸기**: 휴대폰 갤러리 선택 창이 열려요.
- **저장하기**(문장 카드·독서 유형 카드·스티커): 사진 앱의 `Pictures/DokDok` 폴더에 저장돼요.
- **공유하기**: 안드로이드 공유 창이 열려요. (지금은 글·링크만 공유돼요.)
- 휴대폰 글자 크기 설정과 상관없이 화면 비율이 유지되도록 글자 확대를 고정했어요.

## 구성
- 패키지 이름: `app.dokdok.reader` / 앱 이름: 독독 / 최소 Android 8.0(API 26)
- `app/src/main/java/app/dokdok/reader/MainActivity.java`: 웹뷰 화면, 뒤로가기·사진 선택·저장·공유 연결
- `app/src/main/res/drawable/ic_launcher_fg.xml`: 앱 아이콘(라벤더 책 + 강아지 발바닥)
