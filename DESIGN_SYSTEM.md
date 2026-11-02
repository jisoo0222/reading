# 똑독(DDOKDOK) 디자인 시스템

피그마 파일 **똑독-DDOKDOK-**의 Variables·Effect Styles·컴포넌트를 기준으로 정리한 문서예요. (2026.11.02 기준)

- 화면 크기: **412 × 917**
- 글꼴: **Pretendard**
- 앱(`Reading_app.html`)의 CSS 변수는 아래 토큰과 연결돼 있어요. → [7. 앱 CSS 변수 연결](#7-앱-css-변수-연결)

---

## 1. 색 · 기본 색 (Color Primitives)

| 단계 | green | neutral | pink | yellow |
|---|---|---|---|---|
| 0 | | `#FFFFFF` | | |
| 100 | `#DCF5E2` | `#F6F6F6` | `#FFE0EA` | `#FFFEF5` |
| 200 | `#C6EED0` | `#E3E3E3` | `#FFBBD1` | `#FEFCEA` |
| 300 | `#A8E5B7` | `#D5D5D5` | `#FF9FBE` | `#FBF7D7` |
| 400 | `#61D298` | `#C5C5C5` | `#FF7BA6` | `#FEF7BB` |
| 500 | `#4CAE85` | `#B1AFAE` | `#FF4C86` | `#FFF3A0` |
| 600 | `#267B58` | `#898585` | `#E4195B` | |
| 700 | `#186344` | `#666161` | `#BC144A` | |
| 800 | `#174D37` | `#444141` | `#7C1335` | |
| 900 | `#203726` | `#1F1E1E` | | |
| 1000 | | `#000000` | | |

## 2. 색 · 용도별 색 (Color, light / dark)

| 토큰 | light | dark | 쓰는 곳 |
|---|---|---|---|
| `brand/primary` | green/500 `#4CAE85` | green/300 `#A8E5B7` | 메인 버튼, 선택된 탭, 진행 바 |
| `brand/primary-hover` | green/600 `#267B58` | green/100 `#DCF5E2` | 누른 상태, 홈 버튼 선택 |
| `brand/secondary` | pink/400 `#FF7BA6` | pink/300 `#FF9FBE` | 보조 강조 |
| `brand/secondary-hover` | pink/600 `#E4195B` | pink/100 `#FFE0EA` | 보조 강조 누른 상태 |
| `brand/default` | neutral/400 `#C5C5C5` | neutral/100 `#F6F6F6` | 선택 안 된 탭, 저자 이름 |
| `text/default` | neutral/900 `#1F1E1E` | neutral/100 `#F6F6F6` | 기본 글씨 |
| `text/sub` | neutral/700 `#666161` | neutral/400 `#C5C5C5` | 보조 글씨, 링크 |
| `text/emphasis` | neutral/900 `#1F1E1E` | neutral/100 `#F6F6F6` | 섹션 제목, 강조 숫자 |
| `text/on-primary` | neutral/0 `#FFFFFF` | neutral/900 `#1F1E1E` | 메인 버튼 위 글씨 |
| `text/disabled` | neutral/400 `#C5C5C5` | neutral/600 `#898585` | 비활성 글씨 |
| `Background/default` | neutral/100 `#F6F6F6` | neutral/900 `#1F1E1E` | 화면 배경 |
| `Background/door` | neutral/200 `#E3E3E3` | neutral/800 `#444141` | 홈·마이페이지 위쪽 영역, 칸 바탕 |
| `Background/card` | neutral/0 `#FFFFFF` | neutral/800 `#444141` | 카드 |
| `Background/section` | neutral/200 `#E3E3E3` | neutral/800 `#444141` | 구역 배경 |
| `border/default` | neutral/200 `#E3E3E3` | neutral/800 `#444141` | 기본 테두리 |
| `border/brand` | neutral/300 `#D5D5D5` | neutral/700 `#666161` | 요일 칸 테두리 |
| `divider` | neutral/300 `#D5D5D5` | neutral/800 `#444141` | 구분선 |
| `state/selected-bg` | neutral/200 `#E3E3E3` | neutral/800 `#444141` | 선택·완료 바탕 (요일 칸, 칩, 안 읽은 알림) |
| `state/selected-text` | neutral/900 `#1F1E1E` | neutral/100 `#F6F6F6` | 선택·완료 글씨 |
| `progress/track` | neutral/200 `#E3E3E3` | neutral/800 `#444141` | 진행 바 바탕 |
| `progress/fill` | green/500 `#4CAE85` | green/300 `#A8E5B7` | 진행 바 채움 |
| `state/success` | green/500 | green/300 | 완독·달성 |
| `state/warning` | yellow/500 `#FFF3A0` | yellow/500 | 주의 |
| `state/error` | pink/600 `#E4195B` | pink/500 `#FF4C86` | 삭제 경고 |
| `state/badge` | pink/500 `#FF4C86` | pink/500 | 알림 점 |
| `overlay` | `#000000` 40% | `#000000` 60% | 팝업 뒤 어둡게 |
| `Shadow/primary` | `#898585` 50% | `#000000` 50% | 그림자 색 |
| `Shadow/secondary` | `#666161` 50% | `#000000` 60% | 그림자 색 |

> 책 표지 색(12가지 조합)은 책을 구분하는 정보라 이 팔레트와 따로 관리해요. 팔레트를 바꿀 때 바꾸지 않아요.

> **초록은 포인트에만 써요.** `brand/primary`(초록)는 메인 버튼(이어읽기·독서하기·검사하기), 내비게이션의 선택된 탭과 홈 버튼, 진행 바 채움, 독서 달력의 읽은 날 별, 안 읽은 알림 점, 문구점의 선택된 탭 막대·동전 아이콘처럼 **포인트가 필요한 곳에만** 써요. 제목·칩·태그·배지·카드·배경·친구 프로필·책장 선반 등 나머지는 모두 뉴트럴(`neutral` 계열)로 써요.

## 3. 글자 (Typography)

**기본 값 (Typography Primitives)**

| 종류 | 값 |
|---|---|
| Family Sans | Pretendard |
| Weight | Thin 100 · Extra Light 200 · Light 300 · Regular 400 · Medium 500 · Semibold 600 · Bold 700 · Extra Bold 800 · Black 900 |
| Scale | 01 `7` · 02 `10` · 03 `13` · 04 `16` · 05 `20` · 06 `24` · 07 `32` · 08 `36` · 09 `40` · 10 `48` |
| Leading | Narrow 100% · Medium 150% · Wide 200% |

**용도별 (Typography)**

| 용도 | 굵기 | Large | Base | Small | 줄 간격 |
|---|---|---|---|---|---|
| Title Page | Bold 700 | 40 | 32 | 24 | |
| Subtitle | Semibold 600 | 16 | 13 | 10 | |
| Body | Regular 400 | 16 | 13 | 10 | 150% |
| Caption | | | 12 | 11 | |
| Button | Semibold 600 | | 16 | | |
| Number | Bold 700 | | 20 | | |

## 4. 크기 · 간격 (Size)

| 종류 | 토큰 = 값 |
|---|---|
| 모서리 (4단계로 통일) | **10** `Radius/book-cover` · `Radius/cell` · `Radius/card-sm` · `Radius/input` / **20** `Radius/button` · `Radius/popup` / **25** `Radius/card` / **999** `Radius/bar` · `Radius/chip` |
| 간격 | `Space/xs` 4 · `Space/sm` 8 · `Space/gap` 10 · `Space/md` 12 · `Space/lg` 16 · `Space/leftright_side` **16** (화면 양쪽 여백) · `Space/section` 20 · `Space/xl` 24 · `Space/2xl` 32 · `Space/updown_side` 70 |
| 요소 크기 | `Size/header` 56 · `Size/icon-sm` 16 · `Size/icon-md` 20 · `Size/icon-lg` 24 · `Size/touch-min` 44 · `Size/home-button` 50 · `Size/nav-height` 91 |

## 5. 효과 (Effect Styles)

| 이름 | 값 |
|---|---|
| primary | Drop shadow · x 0 · y 4 · blur 4 · `#898585` 50% |
| secondary | Drop shadow · x 0 · y 4 · blur 4 · `#666161` 50% |

## 6. 컴포넌트

### navigation_bar (하단 내비게이션)
- 바탕: `Background/card`, 테두리 1.5px `brand/primary`, 위쪽 모서리 45.5, 높이 91
- 버튼 5개(도서관 · 디지털 문구점 · 홈 · 커뮤니티 · 마이페이지), 버튼 사이 25, 묶음 폭 358
- 버튼: 아이콘(높이 18~20) + 글자 11 Semibold, 아이콘과 글자 사이 5
- 색: 기본 `brand/default` `#C5C5C5` → 선택 `brand/primary` `#4CAE85`
- 홈: 지름 50 원 + 흰 집 아이콘, 기본 `#4CAE85` → 선택 `#267B58`
- 변형: `Property 1 = Default / selected`, 다크용 `navigation_bar_dark`

### 중요 버튼
- 높이 56, 모서리 `Radius/button` 20, 바탕 `brand/primary`, 글자 `text/on-primary` 16 Semibold (예: 이어읽기)

### card-white
- 바탕 `Background/card`, 모서리 `Radius/card-sm` 10, 테두리 없음 (홈 커뮤니티 인기글 카드, 목록 카드)

### 홈 화면 (메인화면 412×917)
- 위쪽: `Background/door` 바탕 위에 흰 아치(폭 412 · 높이 230), 인사말 "안녕하세요,"(24 Bold) / "OO님!"(32 Bold), 오른쪽에 캐릭터 도기, 알림 아이콘(25, `brand/primary`)
- 지금 읽는 책: 표지 93×137(모서리 10) · 세로선 3px `brand/primary` · "지금 읽는 책" 12 Semibold · 책 제목 24 · 저자 12 `brand/default` · 진행 바 8(`progress/track`·`progress/fill`) · 쪽수 12 · 퍼센트 12 Extra Bold `text/emphasis` · 중요 버튼
- 구역 구분: 카드 상자 대신 1px `divider`
- 구역 제목: 16 Semibold `text/emphasis`, 오른쪽 링크 12 Medium `text/sub` + 화살표 16
- 이번 주 기록: "N일 읽었어요", 요일 칸 39×36(모서리 10, 테두리 `border/brand`, 읽은 날 바탕 `Background/door`, 글자 12 `text/emphasis`), 아래 요일 S M T W T F S(11 Semibold)
- 오늘의 포인트: 진행 바 8(채움 `brand/primary-hover`) + "100P /300P"(12)
- 커뮤니티 인기글: card-white 2개 나란히(사이 10)
- 위 칸(지금 읽는 책 · 검사 권유 · 첫 책 고르기 · 완독 후 추천)은 높이 **209로 고정**하고 그 안에서만 내용이 바뀜 → 아래 구역 위치는 항상 같음

### 홈 간격 (Space 토큰)
| 위치 | 간격 |
|---|---|
| 화면 좌우 여백 | `Space/leftright_side` 16 (모든 화면 같음) |
| 위쪽 아치 시작 | `Space/sm` 8 |
| 위쪽 영역 → 지금 읽는 책 | `Space/xl` 24 |
| 표지 → 세로선 / 세로선 → 글 | `Space/sm` 8 / `Space/md` 12 |
| 책 정보 → 이어읽기 버튼, 구분선 → 구역 제목 | `Space/lg` 16 |
| 구역 제목 → 내용 | `Space/sm` 8 |
| 구역 끝 → 다음 구분선 | `Space/section` 20 |
| 커뮤니티 카드 사이 | `Space/gap` 10 |
| 위쪽 영역 높이 | 258 |

### 디지털 문구점
- 포인트 카드: 381×127, 바탕 `Background/door`, 모서리 `Radius/card` 25, "나의 포인트" 16 Medium, 동전 아이콘 32 + 포인트 24 Semibold, 보관함 알약 버튼(흰 바탕, 모서리 200, 12 Medium `brand/primary`)
- 탭 4개(전체보기 · 형광펜 · 스티커 · 제작하기): 아이콘 30 + 글자 11 Semibold, 기본 `brand/default` → 선택 `brand/primary` + 아래 막대 67×6, 탭 줄 아래 1px 선
- 상품 목록: 바탕 `Background/default`, 3열, 카드 121×122 흰색 모서리 25, 가로 8 · 세로 25 간격, 이름 16 Semibold `text/default`, 가격 16 Regular `text/sub`

### 마이페이지 (피그마 1107:582 참고)
- 위쪽: `Background/door` 바탕 책장, 선반 `brand/primary` 15
- 시트: 흰 바탕, 위쪽 모서리 25, 손잡이 50×6 `Background/door`, 좌우 24
- 프로필: 사진 60 · 이름 20 Semibold · "연령 · 하루 N쪽 목표" 12 `text/sub` · 오른쪽 원형 아이콘 버튼 30(1px 테두리)
- AI 독서 성향: 회색(`Background/default`) 카드 모서리 20, 안쪽 16·20, 성향 코드 배지(`brand/primary`, 모서리 10, 12 Extra Bold 흰 글씨) + 이름 14 Semibold
- 내 친구: 사진 50 + 이름 14 Medium, 사이 28
- 읽은 책: 표지 35×50(모서리 5) · 제목 14 Semibold · 저자 12, 줄 사이 1px `Background/door`, 상태 알약(높이 30, 모서리 200) — 읽는 중은 흰 바탕+초록 테두리, 완독은 초록 바탕+흰 글씨

### 공통 규칙 (피그마 시안이 없는 화면 · 메인 화면 기준)
도서관 · 장르 · 인기 순위 · 커뮤니티 · 게시글 · 알림 · 독서 달력 · 책 상세 · 설정 · 읽은 책 · 마이페이지 · 가입 단계에 같은 규칙을 써요.
- 화면 양쪽 여백 16 (`Space/leftright_side`), 바탕 `Background/default`
- 위쪽 제목 줄: 높이 56 (`Size/header`), 흰 바탕, 아래 1px `divider`, 제목 18 Bold
- 구역: 상자 없이 1px `divider`로 나눔 (구분선 → 제목 16, 구역 사이 20), 제목 16 Semibold `text/emphasis`, 오른쪽 "전체 보기" 12 Medium `text/sub` + 화살표 16
- 목록 카드: 흰 바탕, 모서리 10, 안쪽 여백 14~16, 최소 높이 64 (순위 88), 제목 16 Semibold · 보조 13
- 버튼: 높이 56, 모서리 20, 16 Semibold / 보조 버튼은 흰 바탕 + 1.5px `brand/primary`
- 칩: 높이 40, 모서리 999, 14 Semibold, 기본은 흰 바탕 + 1px `state/selected-bg` 테두리 + `text/sub`, 선택하면 `state/selected-bg` 바탕 + `state/selected-text`
- 입력칸: 모서리 10
- 팝업: 모서리 20, 뒤 배경 `overlay` 40%
- 장르 아이콘 원 56 + 이름 13 Semibold, 인기 책 카드 폭 124

### 아이콘
- Iconify 플러그인 아이콘 사용(uil · majesticons · ant-design · ri). 선 굵기 2, 끝 둥글게

## 7. 앱 CSS 변수 연결

| 앱 CSS 변수 | 피그마 토큰 |
|---|---|
| `--pri` | `brand/primary` |
| `--emp` | `text/emphasis` (= `brand/primary-hover`) |
| `--ink` | `text/default` |
| `--sub` | `text/sub` |
| `--onpri` | `text/on-primary` |
| `--bg` | `Background/default` |
| `--card` | `Background/card` |
| `--lav` | `Background/door` · `progress/track` · `border/brand` |
| `--line` | `border/default` |
| `--divider` | `divider` |
| `--r-cover` · `--r-cell` · `--r-btn` · `--r-card` | `Radius/book-cover` · `Radius/cell` · `Radius/button` · `Radius/card` |
| `--sh1` | Effect `primary` |
