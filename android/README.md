# 똑독 안드로이드 앱 (에뮬레이터 실행용)

웹 프로토타입 `../Reading_app.html`을 그대로 띄우는 안드로이드 앱이에요.
빌드할 때마다 이 HTML이 앱 안으로 자동 복사되므로, 화면 수정은 지금처럼 HTML 파일 하나만 고치면 돼요.

## 에뮬레이터에서 실행하기
1. [Android Studio](https://developer.android.com/studio)를 설치하고 실행해요.
2. **Open** → 이 저장소의 `android` 폴더를 선택해요. (처음 열면 Gradle 동기화에 몇 분 걸려요.)
3. 오른쪽 위 **Device Manager**에서 가상 기기를 만들어요. 예: Pixel 7, Android 14(API 34).
4. 초록색 **Run ▶** 버튼을 누르면 에뮬레이터에 '똑독' 앱이 설치되고 실행돼요.

## 고친 내용을 바로 보기 (빌드 없이 새로고침)
1. 컴퓨터 터미널에서 저장소 폴더로 이동해 `node dev-server.js` 를 실행해요. (끄려면 Ctrl + C)
2. Android Studio에서 **Run ▶** 으로 앱을 한 번 실행해요. (이후에는 다시 빌드할 필요 없어요.)
3. `Reading_app.html` 을 고치고 저장하면 에뮬레이터 화면이 자동으로 새로고침돼요.
- 개발 서버는 1분마다 GitHub 브랜치의 최신 `Reading_app.html` 을 확인해 자동으로 내려받아요. (Claude가 고친 내용이 그대로 반영돼요)
  내 컴퓨터에서 직접 고친 내용을 지키고 싶으면 `node dev-server.js --local` 로 켜요.
- 컴퓨터 브라우저에서 `http://localhost:5173` 을 열어도 같은 화면이 자동 새로고침돼요.
- 개발 서버가 꺼져 있으면 앱은 자기 안에 들어 있는 화면(마지막 빌드 때의 HTML)을 띄워요.
- 이 연결은 디버그 실행에서만 동작하고, 배포용(release) 앱에는 들어가지 않아요.
- 실제 휴대폰을 USB로 연결해서 쓸 때는 `adb reverse tcp:5173 tcp:5173` 을 한 번 실행한 뒤,
  `app/build.gradle` 의 `10.0.2.2` 를 `localhost` 로 바꾸면 돼요.

## 앱에서 달라지는 점
- 휴대폰의 **뒤로가기**: 열린 팝업을 닫고, 없으면 앱 안의 '뒤로' 버튼처럼 동작해요. 첫 화면에서는 앱이 닫혀요.
- **프로필 사진 바꾸기**: 휴대폰 갤러리 선택 창이 열려요.
- **저장하기**(문장 카드·독서 유형 카드·스티커): 사진 앱의 `Pictures/DdokDok` 폴더에 저장돼요.
- **공유하기**: 안드로이드 공유 창이 열려요. (지금은 글·링크만 공유돼요.)
- 휴대폰 글자 크기 설정과 상관없이 화면 비율이 유지되도록 글자 확대를 고정했어요.

## 구성
- 패키지 이름: `app.dokdok.reader` / 앱 이름: 똑독 / 최소 Android 8.0(API 26)
- `app/src/main/java/app/dokdok/reader/MainActivity.java`: 웹뷰 화면, 뒤로가기·사진 선택·저장·공유 연결
- `app/src/main/res/drawable/ic_launcher_fg.xml`: 앱 아이콘(라벤더 책 + 강아지 발바닥)
