-- Supabase SQL Editor에서 파일 전체를 실행해요.
-- 기존 profiles / member_settings 설치 뒤에 실행하며 재실행해도 기록은 지우지 않아요.
begin;

create table if not exists public.ddok_states (
 user_id uuid primary key references auth.users(id) on delete cascade,
 revision bigint not null default 0,
 state jsonb not null default '{"version":1}',
 updated_at timestamptz not null default now(),
 check (revision >= 0 and jsonb_typeof(state) = 'object' and octet_length(state::text) <= 5242880)
);
create table if not exists public.ddok_wallets (
 user_id uuid primary key references auth.users(id) on delete cascade,
 balance integer not null default 0 check (balance >= 0)
);
create table if not exists public.ddok_point_events (
 user_id uuid not null references auth.users(id) on delete cascade,
 event_key text not null,
 amount integer not null check (amount between -100000 and 300),
 label text not null,
 day date not null,
 mission text,
 book_id integer,
 created_at timestamptz not null default now(),
 primary key(user_id, event_key)
);
create table if not exists public.ddok_catalog (
 id text primary key,
 name text not null,
 price integer not null check (price between 0 and 100000)
);
create table if not exists public.ddok_owned_items (
 user_id uuid not null references auth.users(id) on delete cascade,
 item_id text not null references public.ddok_catalog(id),
 purchased_at timestamptz not null default now(),
 primary key(user_id, item_id)
);
create table if not exists public.ddok_read_days (
 user_id uuid not null references auth.users(id) on delete cascade,
 day date not null,
 primary key(user_id, day)
);
create table if not exists public.ddok_books (
 id integer primary key, title text not null, pages integer not null check(pages > 0)
);
-- 앱의 현재 본문 페이지 수예요. 새 본문을 넣으면 이 목록도 갱신해요.
insert into public.ddok_books(id,title,pages) values
 (4,'백치 아다다',61),(5,'동백꽃',36),(6,'날개',101),(7,'홍경래전',318),
 (8,'죄와 벌',187),(9,'메밀꽃 필 무렵',40),(10,'운수 좋은 날',52),
 (65,'새벽 세 시의 사서',6),(66,'고양이가 접어 둔 페이지',6),
 (67,'맹자 · 양혜왕 상',35),(68,'맹자 · 양혜왕 하',48),(69,'지봉유설',2627),
 (70,'마지막 정류장',5),(71,'분실물 보관소',5),(72,'오늘의 기억을 대여하시겠습니까',6),
 (73,'죽여드립니다',7),(74,'우산을 빌려드립니다',5),(75,'13번째 방',5),(76,'벽장 안의 사람',5),
 (77,'목요일의 빈 의자',6),
 (78,'화성행 반품 택배',6),
 (79,'어제의 날씨를 팝니다',6),
 (80,'302호의 연습곡',6),
 (81,'사라진 우승 트로피',6),
 (82,'파도가 멈춘 지도',6),
 (83,'퇴근길의 작은 탐사선',6),
 (84,'한 장 남은 필름',6)
 on conflict(id) do update set title=excluded.title,pages=excluded.pages;
insert into public.ddok_catalog(id,name,price) values
 ('PN0','접힌 스티커',200),('PN1','타원 스티커',200),('PN2','테이프 스티커',250),
 ('PN3','체크 스티커',250),('PN4','클립 스티커',250),('PN5','하트 스티커',300),
 ('PN6','스프링 노트',300),('PN7','마스킹 스티커',300),('PN8','말풍선 스티커',350),
 ('HL0','펜',150),('HL1','마커',200),('HL2','연필',150),('HL3','테마펜',250),('HL4','붓펜',300),('HL5','점선펜',250),
 ('BM0','리본',150),('BM1','깃발',150),('BM2','탭',200),('BM3','화살표',200),
 ('TH0','기본',0),('TH1','새벽',500),('TH2','숲',500),('TH3','노을',600)
 on conflict(id) do update set name=excluded.name,price=excluded.price;

alter table public.ddok_states enable row level security;
alter table public.ddok_wallets enable row level security;
alter table public.ddok_point_events enable row level security;
alter table public.ddok_owned_items enable row level security;
alter table public.ddok_read_days enable row level security;
alter table public.ddok_catalog enable row level security;
alter table public.ddok_books enable row level security;
revoke all on public.ddok_states,public.ddok_wallets,public.ddok_point_events,public.ddok_owned_items,public.ddok_read_days,public.ddok_catalog,public.ddok_books from anon,authenticated;
grant select on public.ddok_states,public.ddok_wallets,public.ddok_point_events,public.ddok_owned_items,public.ddok_read_days,public.ddok_catalog,public.ddok_books to authenticated;
drop policy if exists ddok_own on public.ddok_states;
create policy ddok_own on public.ddok_states for select to authenticated using ((select auth.uid())=user_id);
drop policy if exists ddok_own on public.ddok_wallets;
create policy ddok_own on public.ddok_wallets for select to authenticated using ((select auth.uid())=user_id);
drop policy if exists ddok_own on public.ddok_point_events;
create policy ddok_own on public.ddok_point_events for select to authenticated using ((select auth.uid())=user_id);
drop policy if exists ddok_own on public.ddok_owned_items;
create policy ddok_own on public.ddok_owned_items for select to authenticated using ((select auth.uid())=user_id);
drop policy if exists ddok_own on public.ddok_read_days;
create policy ddok_own on public.ddok_read_days for select to authenticated using ((select auth.uid())=user_id);
drop policy if exists ddok_catalog_read on public.ddok_catalog;
create policy ddok_catalog_read on public.ddok_catalog for select to authenticated using (true);
drop policy if exists ddok_books_read on public.ddok_books;
create policy ddok_books_read on public.ddok_books for select to authenticated using (true);

-- 내부 함수는 API 호출 권한을 주지 않아요.
create or replace function public.ddok_private_pages(p_user uuid)
returns table(book_id integer,page_no integer) language sql stable security definer set search_path='' as $$
 select b.id,split_part(k,'-',2)::integer
 from public.ddok_states s,
 lateral jsonb_object_keys(case when jsonb_typeof(s.state#>'{reading,RDY,p}')='object' then s.state#>'{reading,RDY,p}' else '{}'::jsonb end) k
 join public.ddok_books b on b.id=case when k ~ '^[0-9]{1,4}-[0-9]{1,5}$' then split_part(k,'-',1)::integer end
 where s.user_id=p_user and s.state#>>'{reading,RDY,d}'=to_char(now() at time zone 'Asia/Seoul','YYYY.MM.DD')
 and case when k ~ '^[0-9]{1,4}-[0-9]{1,5}$' then split_part(k,'-',2)::integer else 0 end between 1 and b.pages
$$;
create or replace function public.ddok_save_state(p_state jsonb,p_revision bigint)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); r bigint;
begin
 if u is null then raise exception 'login_required' using errcode='42501'; end if;
 if p_state is null or jsonb_typeof(p_state)<>'object' or p_state->>'version' is distinct from '1'
 or octet_length(p_state::text)>5242880 or p_revision is null or p_revision<0 then
  raise exception 'invalid_state' using errcode='22023';
 end if;
 insert into public.ddok_states(user_id) values(u) on conflict do nothing;
 update public.ddok_states set state=p_state,revision=revision+1,updated_at=now()
 where user_id=u and revision=p_revision returning revision into r;
 if r is null then raise exception 'state_conflict' using errcode='40001'; end if;
 if exists(select 1 from public.ddok_private_pages(u)) then
  insert into public.ddok_read_days(user_id,day) values(u,(now() at time zone 'Asia/Seoul')::date) on conflict do nothing;
 end if;
 return jsonb_build_object('revision',r);
end $$;

create or replace function public.ddok_private_wallet(p_user uuid)
returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object(
  'balance',coalesce((select balance from public.ddok_wallets where user_id=p_user),0),
  'owned',coalesce((select jsonb_object_agg(item_id,1) from public.ddok_owned_items where user_id=p_user),'{}'::jsonb),
  'points',coalesce((select jsonb_agg(jsonb_build_object('amount',e.amount,'label',e.label,'day',to_char(e.day,'YYYY.MM.DD'),'at',e.created_at) order by e.created_at desc,e.event_key)
   from (select * from public.ddok_point_events where user_id=p_user and amount<>0 order by created_at desc,event_key limit 500) e),'[]'::jsonb),
  'day',jsonb_build_object('d',to_char(now() at time zone 'Asia/Seoul','YYYY.MM.DD'),
   'act',coalesce((select sum(greatest(amount,0)) from public.ddok_point_events where user_id=p_user and day=(now() at time zone 'Asia/Seoul')::date),0),
   'got',coalesce((select jsonb_object_agg(mission,amount) from public.ddok_point_events where user_id=p_user and day=(now() at time zone 'Asia/Seoul')::date and mission is not null),'{}'::jsonb)))
$$;
create or replace function public.ddok_wallet()
returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();
begin
 if u is null then raise exception 'login_required' using errcode='42501'; end if;
 insert into public.ddok_wallets(user_id) values(u) on conflict do nothing;
 return public.ddok_private_wallet(u);
end $$;

create or replace function public.ddok_claim_point(p_mission text,p_day text,p_book integer default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); d date:=(now() at time zone 'Asia/Seoul')::date;
 reward integer; earned integer; granted integer; title text; event text; goal integer; snapshot jsonb;
begin
 if u is null then raise exception 'login_required' using errcode='42501'; end if;
 if p_day is distinct from to_char(d,'YYYY.MM.DD') then raise exception 'reward_expired' using errcode='22023'; end if;
 select x.p,x.n into reward,title from (values
  ('da',50,'다독'),('talk',50,'토론 참여'),('jeong',100,'정독'),
  ('cmt',20,'코멘트'),('share',20,'공유'),('att',10,'출석'),('done',200,'완독'),('streak',100,'지속 독서')
 ) x(k,p,n) where x.k=p_mission;
 if reward is null then raise exception 'invalid_mission' using errcode='22023'; end if;
 insert into public.ddok_wallets(user_id) values(u) on conflict do nothing;
 perform 1 from public.ddok_wallets where user_id=u for update;
 event:='reward:'||p_day||':'||p_mission;
 if exists(select 1 from public.ddok_point_events where user_id=u and event_key=event) then
  return public.ddok_private_wallet(u)||jsonb_build_object('granted',0,'duplicate',true);
 end if;
 select state into snapshot from public.ddok_states where user_id=u;
 select daily_goal into goal from public.member_settings where id=u;
 if p_mission='jeong' and (select count(*) from public.ddok_private_pages(u))<greatest(coalesce(goal,10),10) then
  raise exception 'mission_not_ready' using errcode='22023';
 elsif p_mission='da' and (select count(*) from (select book_id from public.ddok_private_pages(u) group by book_id having count(*)>=2) b)<2 then
  raise exception 'mission_not_ready' using errcode='22023';
 elsif p_mission='streak' and ((select count(*) from public.ddok_read_days where user_id=u and day between d-2 and d)<3
  or exists(select 1 from public.ddok_point_events where user_id=u and mission='streak' and day>d-3)) then
  raise exception 'mission_not_ready' using errcode='22023';
 elsif p_mission='done' then
  if p_book is null or not exists(select 1 from public.ddok_books b where b.id=p_book
   and case when snapshot#>>array['reading','ST',p_book::text,'pg'] ~ '^[0-9]{1,5}$' then (snapshot#>>array['reading','ST',p_book::text,'pg'])::integer else 0 end>=b.pages) then
   raise exception 'mission_not_ready' using errcode='22023';
  end if;
  if exists(select 1 from public.ddok_point_events where user_id=u and mission='done' and book_id=p_book) then
   return public.ddok_private_wallet(u)||jsonb_build_object('granted',0,'duplicate',true);
  end if;
 end if;
 -- 공유·토론·코멘트는 현재 앱의 활동 신호를 받아요. 공개 커뮤니티 서버 연결 뒤 원본 기록 검증을 추가해요.
 select coalesce(sum(greatest(amount,0)),0) into earned from public.ddok_point_events where user_id=u and day=d;
 granted:=greatest(0,least(reward,300-earned));
 insert into public.ddok_point_events(user_id,event_key,amount,label,day,mission,book_id)
 values(u,event,granted,title||' 미션',d,p_mission,case when p_mission='done' then p_book end);
 update public.ddok_wallets set balance=balance+granted where user_id=u;
 return public.ddok_private_wallet(u)||jsonb_build_object('granted',granted,'duplicate',false);
end $$;

create or replace function public.ddok_buy_item(p_item text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); item public.ddok_catalog%rowtype; funds integer;
begin
 if u is null then raise exception 'login_required' using errcode='42501'; end if;
 select * into item from public.ddok_catalog where id=p_item;
 if not found then raise exception 'unknown_item' using errcode='22023'; end if;
 insert into public.ddok_wallets(user_id) values(u) on conflict do nothing;
 select balance into funds from public.ddok_wallets where user_id=u for update;
 if exists(select 1 from public.ddok_owned_items where user_id=u and item_id=p_item) then return public.ddok_private_wallet(u); end if;
 if funds<item.price then raise exception 'insufficient_points' using errcode='22023'; end if;
 insert into public.ddok_owned_items(user_id,item_id) values(u,p_item);
 insert into public.ddok_point_events(user_id,event_key,amount,label,day)
 values(u,'purchase:'||p_item,-item.price,item.name||' 구매',(now() at time zone 'Asia/Seoul')::date);
 update public.ddok_wallets set balance=balance-item.price where user_id=u;
 return public.ddok_private_wallet(u);
end $$;

revoke all on function public.ddok_private_pages(uuid),public.ddok_private_wallet(uuid) from public,anon,authenticated;
revoke all on function public.ddok_save_state(jsonb,bigint),public.ddok_wallet(),public.ddok_claim_point(text,text,integer),public.ddok_buy_item(text) from public,anon,authenticated;
grant execute on function public.ddok_save_state(jsonb,bigint),public.ddok_wallet(),public.ddok_claim_point(text,text,integer),public.ddok_buy_item(text) to authenticated;
notify pgrst,'reload schema';
commit;
