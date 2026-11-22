-- sync.sql을 이미 실행했다면 이 파일 전체를 SQL Editor에서 실행해요.
-- 새 단편의 독서 미션·완독 포인트 검증에 필요한 책 ID와 페이지 수를 등록해요.
begin;
insert into public.ddok_books(id,title,pages) values
 (77,'목요일의 빈 의자',6),
 (78,'화성행 반품 택배',6),
 (79,'어제의 날씨를 팝니다',6),
 (80,'302호의 연습곡',6),
 (81,'사라진 우승 트로피',6),
 (82,'파도가 멈춘 지도',6),
 (83,'퇴근길의 작은 탐사선',6),
 (84,'한 장 남은 필름',6)
on conflict(id) do update set title=excluded.title,pages=excluded.pages;
commit;
