# 똑독(DDOKDOK) — AI 독서 습관 형성 앱

- 앱 바로가기: https://jisoo0222.github.io/reading/
- 앱 파일: `Reading_app.html` (HTML·CSS·JS가 모두 이 파일 하나에 있음)
- 작업 규칙: [AGENTS.md](AGENTS.md)


## 실행하기

- 최신 디자인은 `Reading_app.html` 하나에 들어 있어요. 브라우저에서 직접 열거나 `node dev-server.js --local`로 실행해요(기본 포트5173).
- Android는 빌드할 때 같은 HTML을 자동으로 복사해요.
- 카카오 연결을 시험할 때는 `node preview-server.cjs`를 실행하고 `http://localhost:5174/`로 열어요. 다른5174 서버가 실행 중이면 먼저 종료해요.
- 카카오 서버 설정은 저장소 밖의 `%LOCALAPPDATA%/DDOKDOK/local-auth/kakao-config.json`에서 읽어요. 필드는 `restApiKey`, 선택 항목 `clientSecret`이에요. 환경 변수 `KAKAO_REST_API_KEY`, `KAKAO_CLIENT_SECRET`을 설정하면 파일 값보다 우선해요.
- 카카오 Developers에 등록할 개발용 Redirect URI는 `http://localhost:5174/auth/kakao/callback`이에요.
- 로컬 가입 여부·닉네임·목표·성향 답변은 같은 설정 폴더의 `kakao-users.json`에 저장해요. 키·Client Secret·회원 데이터는 Git에 올리지 않아요.
- GitHub Pages는 화면 미리보기용이에요. 카카오 인증 서버는 별도로 배포해야 하고, 이메일·Google 가입은 화면 확인용이에요.
