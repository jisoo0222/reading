-- sync.sql 다음에 실행해요. 관리자 권한은 SQL Editor에서만 부여해요.
begin;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 nickname text not null default '', avatar_url text, reading_type text, discoverable boolean not null default false
);
create table if not exists public.member_settings (
 id uuid primary key references auth.users(id) on delete cascade,
 age integer, daily_goal integer not null default 10, reading_answers jsonb not null default '[null,null,null,null]', onboarded boolean not null default false
);
create table if not exists public.ddok_eligibility (
 user_id uuid primary key references auth.users(id) on delete cascade, confirmed_at timestamptz not null default now(), version text not null
);
create table if not exists public.ddok_community_terms (
 user_id uuid primary key references auth.users(id) on delete cascade, version text not null, accepted_at timestamptz not null default now()
);
create table if not exists public.ddok_moderators (user_id uuid primary key references auth.users(id) on delete cascade);
create table if not exists public.ddok_restrictions (
 user_id uuid primary key references auth.users(id) on delete cascade, banned boolean not null default false, until_at timestamptz, reason text not null default ''
);
create table if not exists public.ddok_account_closures (user_id uuid primary key references auth.users(id) on delete cascade, requested_at timestamptz not null default now());
create table if not exists public.ddok_posts (
 id uuid primary key default gen_random_uuid(), author_id uuid not null references auth.users(id) on delete cascade,
 kind text not null check(kind in ('자유','같이','코멘트','밸런스')), body text not null check(char_length(body) between 1 and 5000),
 visibility integer not null default 0 check(visibility between 0 and 2), book_id integer, book_title text, book_author text,
 image text check(image is null or (octet_length(image)<=1048576 and image ~ '^data:image/(png|jpeg|webp);base64,')),
 options jsonb, hidden boolean not null default false, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.ddok_comments (
 id uuid primary key default gen_random_uuid(), post_id uuid not null references public.ddok_posts(id) on delete cascade,
 author_id uuid not null references auth.users(id) on delete cascade, body text not null check(char_length(body) between 1 and 1000),
 hidden boolean not null default false, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.ddok_blocks (
 user_id uuid not null references auth.users(id) on delete cascade, blocked_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(), primary key(user_id,blocked_id), check(user_id<>blocked_id)
);
create table if not exists public.ddok_friendships (
 requester uuid not null references auth.users(id) on delete cascade, recipient uuid not null references auth.users(id) on delete cascade,
 accepted boolean not null default false, created_at timestamptz not null default now(), primary key(requester,recipient),check(requester<>recipient)
);
create table if not exists public.ddok_post_likes (
 user_id uuid not null references auth.users(id) on delete cascade, post_id uuid not null references public.ddok_posts(id) on delete cascade,
 primary key(user_id,post_id)
);
create table if not exists public.ddok_post_votes (
 user_id uuid not null references auth.users(id) on delete cascade, post_id uuid not null references public.ddok_posts(id) on delete cascade,
 choice integer not null check(choice in (0,1)), primary key(user_id,post_id)
);
create table if not exists public.ddok_reports (
 id uuid primary key default gen_random_uuid(), reporter_id uuid not null references auth.users(id) on delete cascade,
 target_type text not null check(target_type in ('post','comment','user')), target_id uuid not null,
 subject_id uuid not null references auth.users(id) on delete cascade,
 reason text not null check(reason in ('harassment','hate','sexual','violence','privacy','copyright','spam','other')),
 detail text not null default '' check(char_length(detail)<=1000), status text not null default 'pending' check(status in ('pending','reviewed')),
 created_at timestamptz not null default now(), reviewed_at timestamptz,
 unique(reporter_id,target_type,target_id)
);
create table if not exists public.ddok_moderation_log (
 id uuid primary key default gen_random_uuid(), moderator_id uuid references auth.users(id) on delete set null,
 subject_id uuid not null references auth.users(id) on delete cascade, report_id uuid references public.ddok_reports(id) on delete set null,
 action text not null, reason text not null, created_at timestamptz not null default now()
);
create index if not exists ddok_posts_feed on public.ddok_posts(created_at desc);
create index if not exists ddok_comments_post on public.ddok_comments(post_id,created_at);
create index if not exists ddok_reports_pending on public.ddok_reports(status,created_at);
alter table public.profiles enable row level security;
alter table public.member_settings enable row level security;
revoke all on public.profiles,public.member_settings from anon,authenticated;
grant select,insert,update on public.profiles,public.member_settings to authenticated;
drop policy if exists ddok_member_own on public.profiles;
create policy ddok_member_own on public.profiles for all to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()));
drop policy if exists ddok_member_boundary on public.profiles;
create policy ddok_member_boundary on public.profiles as restrictive for all to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()));
drop policy if exists ddok_member_own on public.member_settings;
create policy ddok_member_own on public.member_settings for all to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()));
drop policy if exists ddok_member_boundary on public.member_settings;
create policy ddok_member_boundary on public.member_settings as restrictive for all to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()));

-- 화면의 플래그가 아니라 auth.uid()와 비공개 관리자 테이블로 권한을 검사해요.
create or replace function public.ddok_is_moderator(u uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.ddok_moderators where user_id=u)
 and exists(select 1 from auth.users where id=u)
 and not exists(select 1 from public.ddok_account_closures where user_id=u)
 and not exists(select 1 from public.ddok_restrictions where user_id=u and (banned or until_at>now()))
$$;
create or replace function public.ddok_pair_blocked(a uuid,b uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.ddok_blocks where (user_id=a and blocked_id=b) or (user_id=b and blocked_id=a))
$$;
create or replace function public.ddok_post_visible(p uuid,u uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.ddok_posts x where x.id=p and not x.hidden
 and not exists(select 1 from public.ddok_restrictions r where r.user_id=x.author_id and r.banned)
 and not exists(select 1 from public.ddok_account_closures c where c.user_id=x.author_id)
 and not public.ddok_pair_blocked(u,x.author_id)
 and (x.author_id=u or x.visibility=0 or (x.visibility=1 and exists(select 1 from public.ddok_friendships f where f.accepted and ((f.requester=u and f.recipient=x.author_id) or (f.recipient=u and f.requester=x.author_id))))))
$$;
create or replace function public.ddok_community_write_ok(u uuid) returns void language plpgsql security definer set search_path='' as $$
begin
 if u is null or not exists(select 1 from auth.users where id=u) then raise exception 'login_required' using errcode='42501'; end if;
 if exists(select 1 from public.ddok_account_closures where user_id=u) then raise exception 'account_deleting' using errcode='42501'; end if;
 if not exists(select 1 from public.ddok_eligibility where user_id=u) then raise exception 'age_confirmation_required' using errcode='42501'; end if;
 if not exists(select 1 from public.ddok_community_terms where user_id=u and version='2026-11-24.1') then raise exception 'terms_required' using errcode='42501'; end if;
 if exists(select 1 from public.ddok_restrictions where user_id=u and (banned or until_at>now())) then raise exception 'community_restricted' using errcode='42501'; end if;
end $$;
create or replace function public.ddok_post_json(p uuid,u uuid) returns jsonb language sql stable security definer set search_path='' as $$
 select to_jsonb(x)||jsonb_build_object('nickname',coalesce(nullif(a.nickname,''),'독자'),'mine',x.author_id=u,
 'liked',exists(select 1 from public.ddok_post_likes where post_id=x.id and user_id=u),
 'likes',(select count(*) from public.ddok_post_likes where post_id=x.id),
 'comment_count',(select count(*) from public.ddok_comments c where c.post_id=x.id and not c.hidden and not public.ddok_pair_blocked(u,c.author_id)
 and not exists(select 1 from public.ddok_restrictions r where r.user_id=c.author_id and r.banned)),
 'choice',(select choice from public.ddok_post_votes where post_id=x.id and user_id=u),
 'votes',jsonb_build_array((select count(*) from public.ddok_post_votes where post_id=x.id and choice=0),(select count(*) from public.ddok_post_votes where post_id=x.id and choice=1)))
 from public.ddok_posts x left join public.profiles a on a.id=x.author_id where x.id=p
$$;

create or replace function public.ddok_community(p_action text,p_data jsonb default '{}') returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); p uuid; c uuid; target uuid; subject uuid; rowp public.ddok_posts%rowtype;
 report public.ddok_reports%rowtype; v_kind text; v_body text; result jsonb; flag boolean; v_action text;
begin
 if p_action='feed' then
  select coalesce(jsonb_agg(public.ddok_post_json(x.id,u) order by x.created_at desc),'[]') into result
  from (select id,created_at from public.ddok_posts where public.ddok_post_visible(id,u) order by created_at desc limit 100) x;
  return result;
 elsif p_action='detail' then
  p:=(p_data->>'id')::uuid;
  if not public.ddok_post_visible(p,u) then raise exception 'content_unavailable' using errcode='42501'; end if;
  select coalesce(jsonb_agg(to_jsonb(x)||jsonb_build_object('nickname',coalesce(nullif(a.nickname,''),'독자'),'mine',x.author_id=u) order by x.created_at),'[]') into result
  from public.ddok_comments x left join public.profiles a on a.id=x.author_id
  where x.post_id=p and not x.hidden and not public.ddok_pair_blocked(u,x.author_id)
  and not exists(select 1 from public.ddok_restrictions r where r.user_id=x.author_id and r.banned);
  return jsonb_build_object('post',public.ddok_post_json(p,u),'comments',result);
 end if;
 if u is null or not exists(select 1 from auth.users where id=u) then raise exception 'login_required' using errcode='42501'; end if;
 if exists(select 1 from public.ddok_account_closures where user_id=u) then raise exception 'account_deleting' using errcode='42501'; end if;
 if p_action='confirm_age' then
  if p_data->>'age_band' is distinct from '14plus' then raise exception 'minimum_age_14' using errcode='22023'; end if;
  insert into public.ddok_eligibility(user_id,version) values(u,'2026-11-24.1') on conflict(user_id) do nothing;
  return jsonb_build_object('confirmed',true);
 elsif p_action='status' then
  return jsonb_build_object('moderator',public.ddok_is_moderator(u),
   'terms',exists(select 1 from public.ddok_community_terms where user_id=u and version='2026-11-24.1'),
   'age',exists(select 1 from public.ddok_eligibility where user_id=u),
   'restricted',exists(select 1 from public.ddok_restrictions where user_id=u and (banned or until_at>now())));
 elsif p_action='accept_terms' then
  if p_data->>'version' is distinct from '2026-11-24.1' then raise exception 'terms_version' using errcode='22023'; end if;
  if not exists(select 1 from public.ddok_eligibility where user_id=u) then raise exception 'age_confirmation_required' using errcode='42501'; end if;
  insert into public.ddok_community_terms(user_id,version) values(u,'2026-11-24.1') on conflict(user_id) do update set version=excluded.version,accepted_at=now();
  return jsonb_build_object('accepted',true);
 elsif p_action='blocks' then
  select coalesce(jsonb_agg(jsonb_build_object('id',b.blocked_id,'nickname',coalesce(nullif(a.nickname,''),'독자'))),'[]') into result
  from public.ddok_blocks b left join public.profiles a on a.id=b.blocked_id where b.user_id=u;
  return result;
 elsif p_action in ('block','unblock') then
  target:=(p_data->>'user_id')::uuid;
  if target=u or not exists(select 1 from auth.users where id=target) then raise exception 'invalid_target' using errcode='22023'; end if;
  if p_action='block' then insert into public.ddok_blocks(user_id,blocked_id) values(u,target) on conflict do nothing;
   delete from public.ddok_friendships where (requester=u and recipient=target) or (requester=target and recipient=u);
  else delete from public.ddok_blocks where user_id=u and blocked_id=target; end if;
  return jsonb_build_object('blocked',p_action='block');
 elsif p_action='report' then
  v_kind:=p_data->>'target_type';target:=(p_data->>'target_id')::uuid;
  if v_kind='post' and public.ddok_post_visible(target,u) then select author_id into subject from public.ddok_posts where id=target;
  elsif v_kind='comment' then select author_id,post_id into subject,p from public.ddok_comments where id=target and not hidden;
   if not public.ddok_post_visible(p,u) or public.ddok_pair_blocked(u,subject) then subject:=null;end if;
  elsif v_kind='user' then select id into subject from public.profiles where id=target and (discoverable or exists(select 1 from public.ddok_posts where author_id=target and public.ddok_post_visible(id,u)));
  end if;
  if subject is null or subject=u then raise exception 'invalid_target' using errcode='22023'; end if;
  if (select count(*) from public.ddok_reports where reporter_id=u and created_at>now()-interval '1 minute')>=10 then raise exception 'rate_limited' using errcode='22023'; end if;
  insert into public.ddok_reports(reporter_id,target_type,target_id,subject_id,reason,detail)
   values(u,v_kind,target,subject,p_data->>'reason',coalesce(p_data->>'detail',''))
   on conflict(reporter_id,target_type,target_id) do update set detail=public.ddok_reports.detail returning id into c;
  return jsonb_build_object('id',c,'submitted',true);
 elsif p_action in ('moderation_queue','moderate') then
  if not public.ddok_is_moderator(u) then raise exception 'moderator_required' using errcode='42501'; end if;
  if p_action='moderation_queue' then
   select coalesce(jsonb_agg(to_jsonb(r)||jsonb_build_object('nickname',a.nickname,'content',case r.target_type when 'post' then (select body from public.ddok_posts where id=r.target_id) when 'comment' then (select body from public.ddok_comments where id=r.target_id) else a.nickname end) order by r.created_at),'[]') into result
   from (select * from public.ddok_reports where subject_id<>u order by (status='pending') desc,created_at desc limit 100) r left join public.profiles a on a.id=r.subject_id; return result;
  end if;
  select * into report from public.ddok_reports where id=(p_data->>'report_id')::uuid for update;
  if not found then raise exception 'report_unavailable' using errcode='22023'; end if;
  if report.subject_id=u then raise exception 'self_moderation' using errcode='42501'; end if;
  v_action:=p_data->>'action';v_body:=trim(coalesce(p_data->>'note',''));
  if char_length(v_body) not between 1 and 1000 then raise exception 'reason_required' using errcode='22023'; end if;
  if v_action in ('hide','restore') then
   if report.target_type='post' then update public.ddok_posts set hidden=(v_action='hide') where id=report.target_id;
   elsif report.target_type='comment' then update public.ddok_comments set hidden=(v_action='hide') where id=report.target_id;
   else raise exception 'invalid_action' using errcode='22023'; end if;
  elsif v_action in ('restrict','ban','release') then
   if report.subject_id=u then raise exception 'self_moderation' using errcode='42501'; end if;
   insert into public.ddok_restrictions(user_id,banned,until_at,reason) values(report.subject_id,v_action='ban',case when v_action='restrict' then now()+interval '24 hours' end,v_body)
   on conflict(user_id) do update set banned=excluded.banned,until_at=excluded.until_at,reason=excluded.reason;
  elsif v_action<>'dismiss' then raise exception 'invalid_action' using errcode='22023'; end if;
  insert into public.ddok_moderation_log(moderator_id,subject_id,report_id,action,reason) values(u,report.subject_id,report.id,v_action,v_body);
  update public.ddok_reports set status='reviewed',reviewed_at=now() where id=report.id;
  return jsonb_build_object('processed',true);
 elsif p_action='delete_post' then
  p:=(p_data->>'id')::uuid;
  if not exists(select 1 from public.ddok_posts where id=p and author_id=u) then raise exception 'owner_required' using errcode='42501';end if;
  delete from public.ddok_reports where (target_type='post' and target_id=p) or (target_type='comment' and target_id in (select id from public.ddok_comments where post_id=p));
  delete from public.ddok_posts where id=p and author_id=u;return jsonb_build_object('deleted',true);
 elsif p_action='delete_comment' then
  c:=(p_data->>'id')::uuid;
  if not exists(select 1 from public.ddok_comments where id=c and author_id=u) then raise exception 'owner_required' using errcode='42501';end if;
  delete from public.ddok_reports where target_type='comment' and target_id=c;
  delete from public.ddok_comments where id=c and author_id=u;return jsonb_build_object('deleted',true);
 end if;
 perform public.ddok_community_write_ok(u);
 if p_action in ('create_post','edit_post') then
  v_body:=trim(coalesce(p_data->>'body',''));v_kind:=p_data->>'kind';
  if v_kind='밸런스' and (p_data->'options' is null or jsonb_typeof(p_data->'options')<>'array' or jsonb_array_length(p_data->'options')<>2 or coalesce(char_length(trim(p_data#>>'{options,0}')),0) not between 1 and 80 or coalesce(char_length(trim(p_data#>>'{options,1}')),0) not between 1 and 80) then raise exception 'invalid_options' using errcode='22023';end if;
  if p_action='create_post' then
   if (select count(*) from public.ddok_posts where author_id=u and created_at>now()-interval '1 minute')>=5 then raise exception 'rate_limited' using errcode='22023';end if;
   insert into public.ddok_posts(author_id,kind,body,visibility,book_id,book_title,book_author,image,options)
    values(u,v_kind,v_body,(p_data->>'visibility')::integer,(p_data->>'book_id')::integer,left(p_data->>'book_title',200),left(p_data->>'book_author',100),p_data->>'image',p_data->'options') returning id into p;
  else
   p:=(p_data->>'id')::uuid;
   update public.ddok_posts set body=v_body,visibility=(p_data->>'visibility')::integer,updated_at=now() where id=p and author_id=u and not hidden;
   if not found then raise exception 'owner_required' using errcode='42501';end if;
  end if;
  return jsonb_build_object('id',p);
 elsif p_action in ('create_comment','edit_comment') then
  v_body:=trim(coalesce(p_data->>'body',''));p:=(p_data->>'post_id')::uuid;
  if not public.ddok_post_visible(p,u) then raise exception 'content_unavailable' using errcode='42501';end if;
  if p_action='create_comment' then insert into public.ddok_comments(post_id,author_id,body) values(p,u,v_body) returning id into c;
  else c:=(p_data->>'id')::uuid;update public.ddok_comments set body=v_body,updated_at=now() where id=c and post_id=p and author_id=u and not hidden;
   if not found then raise exception 'owner_required' using errcode='42501';end if;
  end if;return jsonb_build_object('id',c);
 elsif p_action in ('like','vote') then
  p:=(p_data->>'post_id')::uuid;
  if not public.ddok_post_visible(p,u) then raise exception 'content_unavailable' using errcode='42501';end if;
  if p_action='like' then
   if exists(select 1 from public.ddok_post_likes where user_id=u and post_id=p) then delete from public.ddok_post_likes where user_id=u and post_id=p;
   else insert into public.ddok_post_likes values(u,p);end if;
  else
   if not exists(select 1 from public.ddok_posts where id=p and kind='밸런스') then raise exception 'invalid_target' using errcode='22023';end if;
   insert into public.ddok_post_votes values(u,p,(p_data->>'choice')::integer) on conflict(user_id,post_id) do update set choice=excluded.choice;
  end if;return public.ddok_post_json(p,u);
 end if;
 raise exception 'unknown_action' using errcode='22023';
end $$;

-- 직접 테이블 접근을 막고 RPC가 매 요청의 사용자·공개 범위·제재를 검사해요.
do $$ declare t text;begin
 foreach t in array array['ddok_eligibility','ddok_community_terms','ddok_moderators','ddok_restrictions','ddok_account_closures','ddok_posts','ddok_comments','ddok_blocks','ddok_friendships','ddok_post_likes','ddok_post_votes','ddok_reports','ddok_moderation_log'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('revoke all on public.%I from anon,authenticated',t);
 end loop;
end $$;
revoke all on function public.ddok_is_moderator(uuid),public.ddok_pair_blocked(uuid,uuid),public.ddok_post_visible(uuid,uuid),public.ddok_community_write_ok(uuid),public.ddok_post_json(uuid,uuid) from public,anon,authenticated;
revoke all on function public.ddok_community(text,jsonb) from public;
grant execute on function public.ddok_community(text,jsonb) to anon,authenticated;

-- 이전 JWT가 남아 있어도 삭제됐거나 삭제 중인 계정의 저장을 거절해요.
create or replace function public.ddok_guard_account_write() returns trigger language plpgsql security definer set search_path='' as $$
declare u uuid:=coalesce((to_jsonb(new)->>'user_id')::uuid,(to_jsonb(new)->>'id')::uuid);begin
 if not exists(select 1 from auth.users where id=u) or exists(select 1 from public.ddok_account_closures where user_id=u) then raise exception 'account_unavailable' using errcode='42501';end if;
 if not exists(select 1 from public.ddok_eligibility where user_id=u) then raise exception 'age_confirmation_required' using errcode='42501';end if;
 return new;
end $$;
do $$ declare t text;begin
 foreach t in array array['profiles','member_settings','ddok_states','ddok_wallets','ddok_point_events','ddok_owned_items','ddok_read_days'] loop
  if to_regclass('public.'||t) is not null then
   execute format('drop trigger if exists ddok_account_write on public.%I',t);
   execute format('create trigger ddok_account_write before insert or update on public.%I for each row execute function public.ddok_guard_account_write()',t);
  end if;
 end loop;
end $$;
create or replace function public.ddok_delete_member_rows() returns trigger language plpgsql security definer set search_path='' as $$
begin
 delete from public.ddok_reports where subject_id=old.id or reporter_id=old.id
 or (target_type='comment' and target_id in(select id from public.ddok_comments where author_id=old.id or post_id in(select id from public.ddok_posts where author_id=old.id)));
 delete from public.profiles where id=old.id;
 delete from public.member_settings where id=old.id;
 return old;
end $$;
drop trigger if exists ddok_delete_member_rows on auth.users;
create trigger ddok_delete_member_rows before delete on auth.users for each row execute function public.ddok_delete_member_rows();

-- Edge Function의 서비스 키만 호출할 수 있어요. 사용자 ID는 브라우저에서 받지 않아요.
create or replace function public.ddok_delete_prepare(p_user uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare files jsonb:='[]';begin
 if not exists(select 1 from auth.users where id=p_user) then raise exception 'user_unavailable' using errcode='22023';end if;
 insert into public.ddok_account_closures(user_id) values(p_user) on conflict do nothing;
 if to_regclass('storage.objects') is not null then
  execute 'select coalesce(jsonb_agg(jsonb_build_object(''bucket'',o.bucket_id,''name'',o.name)),''[]''::jsonb) from storage.objects o where to_jsonb(o)->>''owner_id''=$1 or to_jsonb(o)->>''owner''=$1' into files using p_user::text;
 end if;
 return jsonb_build_object('files',files);
end $$;
revoke all on function public.ddok_delete_prepare(uuid) from public,anon,authenticated;
grant execute on function public.ddok_delete_prepare(uuid) to service_role;
revoke all on function public.ddok_guard_account_write(),public.ddok_delete_member_rows() from public,anon,authenticated;
notify pgrst,'reload schema';
commit;
