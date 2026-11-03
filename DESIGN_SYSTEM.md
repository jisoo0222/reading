# 똑독(DDOKDOK) 디자인 시스템 v2

피그마 파일 **똑독-DDOKDOK-**의 라이트모드 시안(섹션 `1108:3473`: 메인화면 · 도서관 · 커뮤니티 · 디지털 문구점)을 기준으로 새로 정리한 문서예요. (2026.11.03 기준)
마이페이지 시안은 참고만 하고, 이 문서의 규칙에 맞춰 바꿔서 적용했어요.

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
| `brand/primary` | green/500 | green/300 | 중요 버튼, 진행 막대 채움·테두리, 네비 선택, 홈 버튼, 책장 선반 |
| `brand/primary-strong` | green/600 | green/100 | 강조 숫자(3%, 1일, 100P) |
| `brand/primary-soft` | green/200 | green/800 | 읽은 날 칸, 선택한 칩 바탕 |
| `brand/secondary` · `-strong` | pink/400 · pink/600 | pink/300 · pink/100 | 보조 색(프로필 발바닥 등) |
| `surface/wall` | green/200 | green/800 | 홈·마이페이지 위쪽 벽(책장 뒤) |
| `surface/sheet` | neutral/100 | neutral/900 | 올라오는 시트, 일반 화면 바탕 |
| `surface/card` | neutral/0 | neutral/800 | 카드, 입력칸, 네비, 동그라미 버튼 |
| `surface/muted` | neutral/100 | neutral/900 | 카드 안 회색 묶음(AI 독서 성향) |
| `text/primary` | neutral/900 | neutral/100 | 제목, 본문 |
| `text/secondary` | neutral/700 | neutral/400 | 저자, 보조 설명, 쪽수 |
| `text/tertiary` | neutral/500 | neutral/500 | "전체 보기"·"달력보기", 요일 라벨, 태그 칩 |
| `text/accent` | green/600 | green/300 | 강조 글자 |
| `text/on-primary` | neutral/0 | neutral/900 | 초록 버튼 위 글자 |
| `text/disabled` | neutral/400 | neutral/600 | 비활성 |
| `border/default` | neutral/400 | neutral/600 | 입력칸, 칩, 요일 칸 테두리 |
| `border/card` | green/500 | green/300 | 카드 테두리 1px |
| `border/subtle` | neutral/200 | neutral/800 | 약한 구분 |
| `divider` | neutral/300 | neutral/800 | 구역 사이 선 |
| `progress/track` · `border` · `fill` | neutral/0 · green/500 · green/500 | neutral/800 · green/300 · green/300 | 진행 막대 |
| `icon/default` · `icon/active` | neutral/400 · green/500 | neutral/600 · green/300 | 네비 아이콘 |
| `nav/border` | green/500 | green/300 | 네비게이션 바 테두리 |
| `shelf/bar` | green/500 | green/600 | 책장 선반 |
| `shelf/book-light` · `mid` · `deep` | yellow/100 · 400 · 500 | yellow/300 · 400 · 500 | 홈 책장 책등 |
| `chip/selected-bg` · `text` | green/200 · green/600 | green/800 · green/300 | 선택한 칩, 상태 알약 |
| `state/success` · `warning` · `error` · `badge` | green/500 · yellow/500 · pink/600 · pink/500 | | 상태 |
| `overlay` | `#000` 40% | `#000` 60% | 팝업 뒤 배경 |
| `Shadow/primary` · `secondary` | | | 그림자 |

> 초록은 **포인트에만** 써요: 중요 버튼, 진행 막대, 카드 테두리, 네비, 책장 선반·벽, 선택 상태. 글자·칩·칸 테두리는 뉴트럴이에요.
> 색은 피그마 시안을 따라요: 링크·요일 라벨 `#B1AFAE`, 카드 안 태그 `#C5C5C5`, 요일 칸 글자 초록, 편지는 떠 있는 버튼 없이 알림 화면 맨 위 "우체통" 줄에서 열어요(새 편지 수는 종 배지에 더해짐).

## 3. 글자 (Typography)

크기 단계(`Scale/01~08`): 11 · 12 · 14 · 16 · 20 · 24 · 32 · 40

| 역할 | 크기 | 굵기 | 쓰는 곳 |
|---|---|---|---|
| Display | 24 | Semibold | 책 제목 |
| Title | 20 | Semibold | 프로필 이름, 위 칸 제목 |
| Heading | 16 | Semibold | 구역 제목, 상단 이름 |
| Body | 14 | Medium | 본문, 친구 이름 |
| Caption | 12 | Medium | 쪽수, "전체 보기", 태그 칩 |
| Label | 11 | Semibold | 네비 글자, 요일 라벨(SUN~SAT) |
| Button | 16 | Semibold | 버튼 글자 |
| Number | 12 | Extra Bold | 강조 숫자(3%, 100P) |

## 4. 크기 · 간격 (Size)

| 토큰 | 값 | 쓰는 곳 |
|---|---|---|
| `Radius/xs` | 5 | 책 썸네일, 책장 책등 |
| `Radius/md` | 10 | **기본 모서리** — 버튼, 입력칸, 카드, 요일 칸 |
| `Radius/lg` | 30 | 홈 슬라이딩 시트 위 모서리, 팝업, 카드(문구점 · AI 성향) |
| `Radius/xl` | 46 | 네비게이션 바 위 모서리, 홈 책 표지 아치(아래는 10) |
| `Radius/full` | 999 | 칩, 진행 막대, 손잡이 |
| `Space/xs·sm·md·lg·xl·2xl` | 4·8·12·16·24·32 | |
| `Space/side` | 16 | 화면 양쪽 여백 |
| `Space/top` | 16 | **기본 윗 여백** — 탭 화면(도서관·문구점·커뮤니티) 첫 요소가 위 16에서 시작 (마이페이지는 시안대로 46) |
| `Space/lg` | 16 | 구역 사이(구분선 위아래) |
| `Size/button` | 56 | 중요 버튼 높이 |
| `Size/input` | 51 | 검색칸 높이 |
| `Size/chip` · `chip-sm` | 36 · 26 | 필터 칩·요일 칸 높이 · 카드 안 태그/상태 알약 |
| `Size/progress` | 8 | 진행 막대 두께 |
| `Size/circle-sm·md·lg` | 40·50·60 | 상단 프로필·알림/찜 동그라미 버튼 · 친구 사진·네비 홈 버튼 · 내 프로필 |
| `Size/handle-w·h` | 50·6 | 시트 손잡이 |
| `Size/shelf` | 16 | 책장 선반 두께 |
| `Size/icon` | **30** | 기본 아이콘(네비 제외) — 버튼 · 탭 · 장르 · 알림 · 검색 · 뒤로 |
| `Size/icon-inline` | 16 | 글자 옆 작은 아이콘 — 전체 보기 화살표 · 좋아요/댓글 숫자 |
| `Size/nav-height` · `header` | 91 · 56 | |

> 차이가 작은 값은 하나로 합쳤어요: 모서리 20·25 → **30**(홈 시트 기준으로 30), 45.5·46.5 → **46** / 칩·요일 칸 34·36 → **36** / 동그라미 40·41 → **40** / 아이콘 14·16 → **16** / 선반 15 → **16**

## 5. 효과 (Effect Styles)

| 이름 | 값 |
|---|---|
| primary | Drop shadow · x 0 · y 4 · blur 4 · `#898585` 50% |
| secondary | Drop shadow · x 0 · y 4 · blur 4 · `#666161` 50% |

## 6. 컴포넌트

### 홈 책장 (벽 + 책장 + 시트)
- 벽 `surface/wall`, 선반 365×16 `shelf/bar`(y208), 시트는 y240부터 `surface/sheet` · 위 모서리 30, 손잡이 50×6 `surface/wall`(y249)
- 왼쪽 위 프로필 40(발바닥) + **닉네임+님** 16 Semibold, 오른쪽 알림 동그라미 버튼 40(흰 바탕)
- 책장은 내가 꽂은 실제 책이에요. 책등 33폭, 한 줄에 8권(높이 131·103·115 반복, `shelf/book-*` 노란색), 제목은 세로 11 Semibold
- 접힌 상태: 첫째 줄만 보여요. 책을 누르면 책 정보, 손잡이·벽을 누르거나 아래로 끌면 펼쳐져요
- 펼치기·접기는 마이페이지에서 쓰던 방식이에요: 책장은 시트 뒤에 깔려 있고, 시트(홈 내용 전체)가 아래로 미끄러져 내려가요(0.5초)
- 펼친 상태(피그마 1153:1461): 3단 책장(줄 아래 y208·397·602) + 오른쪽 아래 강아지, 시트는 맨 아래(손잡이 y815). 시트를 누르거나 위로 밀거나 손잡이를 누르면 접혀요
- 펼친 책장에서 책을 꾹 눌러 옮기고, 휴지통에 놓으면 빠져요. 마지막 칸의 + 로 완독한 책을 꽂아요

### navigation_bar
- 흰 바탕, 위 모서리 46, 테두리 1.5px `nav/border`, 높이 91, 사이 25
- 아이콘 + 글자 11 Semibold, 기본 `icon/default` → 선택 `icon/active`, 가운데 홈 버튼 50

### 중요 버튼
- 높이 56, 모서리 10, `brand/primary` 바탕, 16 Semibold 흰 글씨

### card-white (카드)
- 흰 바탕, 테두리 1px `border/card`, 모서리 10
- 홈 커뮤니티 인기글(위 태그 · 글 1줄 · 아래 좋아요/댓글 아이콘 16 + 숫자), 커뮤니티 글, 마이페이지 프로필 카드

### 진행 막대
- 높이 8, 모서리 999, 흰 바탕 + 1px `progress/border` 테두리 + `progress/fill` 채움
- 쪽수 12 `text/secondary`, 퍼센트 12 Extra Bold `brand/primary-strong`

### 요일 칸
- 39×36, 모서리 10, 1px `border/default`, 안 글자 12
- 읽은 날: `brand/primary-soft` 바탕 + `brand/primary-strong` 글자
- 라벨 SUN · MON · TUE · WED · THU · FRI · SAT (11 Semibold `text/tertiary`)

### 칩
- 필터 칩: 높이 36, 모서리 999, 1px `border/default` + `text/secondary` → 선택하면 `chip/selected-bg` + `chip/selected-text`
- 태그 칩(카드 안): 높이 26, 1px `border/default`, 12 Medium `text/tertiary`
- 상태 알약(읽은 책): 높이 26 — 읽는 중은 흰 바탕 + 1px `brand/primary` 테두리, 완독은 `chip/selected-bg`

### 검색칸 · 동그라미 버튼
- 검색칸: 높이 51, 흰 바탕, 1px `border/default`, 모서리 10, 오른쪽 돋보기
- 검색칸 안 입력창에는 테두리를 따로 두지 않아요(상자 하나)
- 도서관: 검색칸 329 + 찜 동그라미 버튼 40 / 커뮤니티: 검색칸 382, 위 16
- 검색칸 아래 1px `divider`, 위아래 15

### 구역 머리
- 제목 16 Semibold `text/primary`, 오른쪽 "전체 보기"(또는 "달력보기" 등) 12 Medium `text/tertiary` + 화살표 16
- 구역 사이 1px `divider`

### 홈 화면 위치 (412×917)
| 요소 | y |
|---|---|
| 벽 · 책장 | 0–240 |
| 시트 시작 · 손잡이 | 240 · 249 |
| 지금 읽는 책(표지 93×137, 위 칸 높이 209 고정) | 282–491 |
| 이번 주 기록 | 524 |
| 오늘의 포인트 | 639 |
| 커뮤니티 인기글 · 카드 86 | 718–831 |
| 네비게이션 바 | 841 |

### 마이페이지 (피그마 1153:2237)
- 바탕 `surface/sheet`, 좌우 19, 위 46부터 시작 (책장은 홈으로 옮김)
- 프로필 줄: 사진 60 · 이름 20 Semibold · 보조 12 Semibold `#898585`, 오른쪽 동그라미 버튼 40 두 개(아이콘 30, 1px `#898585` 테두리, 사이 22)
  - 자물쇠: 프로필 공개/비공개 전환. 비공개면 초록으로 채워지고, 바꿀 때 "프로필이 비공개로 바뀌었습니다." 안내가 잠깐 떠요
  - 연필: 프로필 편집
- AI 독서 성향: 흰 카드(`surface/card`) 높이 87, 모서리 30, 라벨 12 · 성향 코드 배지(`brand/primary`, 30 높이, 모서리 10, 흰 12 Extra Bold) · 이름 14 Semibold · 화살표 20
- 구역은 1px `divider`로 나눠요(위아래 27). 제목 16 Semibold, "전체 보기" 12 Medium `text/tertiary`
- 내 친구: 사진 50 + 이름 14 Medium, 사이 31
- 읽은 책: 썸네일 35×50(모서리 5) · 제목 14 Semibold · 저자 12, 줄 사이 20. 상태 알약 높이 30, 모서리 999 — 읽는 중은 1.5px 초록 테두리 + 검정 글자, 완독은 초록 바탕 + 흰 글자

### 디지털 문구점
- 포인트 카드: `surface/wall`(연초록) 바탕, 모서리 30, 동전 아이콘 30 + 포인트 24 Semibold, 보관함 알약 버튼(흰 바탕 · 12 Medium `brand/primary`)
- 탭 4개(전체보기 · 형광펜 · 스티커 · 제작하기): 아이콘 30 + 글자 11 Semibold, 선택 `brand/primary` + 아래 막대
- 상품 목록: 3열, 흰 카드, 이름 16 Semibold, 가격 16 Regular `text/secondary`

### 그 밖의 화면 (시안이 없는 화면)
- 바탕 `surface/sheet`, 양쪽 여백 16, 위쪽 제목 줄 56 + 아래 `divider` (화면 맨 위 0에 붙여 잘리지 않게)
- 구역은 상자 없이 `divider`로 나누고, 목록은 흰 카드(모서리 10)
- 버튼·입력칸·칩은 위 컴포넌트 규칙을 그대로 써요

### 아이콘
- Iconify 플러그인 아이콘(uil · majesticons · ant-design · ri). 선 굵기 2, 끝 둥글게
- 크기: 네비를 뺀 모든 단독 아이콘은 **30** 고정. 글자 바로 옆 작은 아이콘만 16
- 아이콘을 감싸는 동그라미 버튼은 40(`Size/circle-sm`), 알림 분류 동그라미는 48
- 떠 있는 버튼(플로팅)은 쓰지 않아요. 예외: 커뮤니티 글쓰기 버튼(글쓰기 유일한 입구)

## 7. 앱 CSS 변수 연결

| 앱 CSS 변수 | 피그마 토큰 |
|---|---|
| `--pri` | `brand/primary` |
| `--strong` | `brand/primary-strong` |
| `--soft` · `--door` | `brand/primary-soft` · `surface/wall` |
| `--bg` | `surface/sheet` |
| `--card` | `surface/card` |
| `--ink` | `text/primary` |
| `--sub` · `--tx2` | `text/secondary` |
| `--tx3` | `text/tertiary` |
| `--onpri` | `text/on-primary` |
| `--bd` | `border/default` |
| `--bd-card` | `border/card` |
| `--divider` | `divider` |
| `--bk-l` · `--bk-m` · `--bk-d` | `shelf/book-light` · `mid` · `deep` |
| `--r-xs` · `--r-md`(=`--r-btn`) · `--r-lg`(=`--r-sheet`·`--r-popup`) · `--r-xl`(=`--r-nav`·`--r-arch`) · `--r-full` | `Radius/xs` · `md` · `lg` · `xl` · `full` |
| `--h-btn` · `--h-input` · `--h-ibtn` · `--h-chip` · `--h-chip-sm` · `--h-prog` · `--h-shelf` | `Size/button` · `input` · `circle-sm` · `chip` · `chip-sm` · `progress` · `shelf` |
| `--sh1` | Effect `primary` |
