@echo off
chcp 65001 >nul
cd /d "%~dp0"
where node >nul 2>nul
if %errorlevel%==0 (
  node dev-server.js
) else if exist "%ProgramFiles%\nodejs\node.exe" (
  "%ProgramFiles%\nodejs\node.exe" dev-server.js
) else (
  echo Node.js를 찾을 수 없어요. https://nodejs.org 에서 LTS 버전을 설치한 뒤 다시 실행해 주세요.
)
pause
