// 테스트 전용 PostgreSQL(WASM). 앱에 포함되지 않아요.
// node tests/community-db.test.cjs <@electric-sql/pglite 설치 경로>
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const {PGlite}=require(process.argv[2]||'@electric-sql/pglite');
async function main(){
 const db=new PGlite();let checks=0;
 await db.exec(`create role anon;create role authenticated;create role service_role bypassrls;
 create schema auth;create table auth.users(id uuid primary key);
 create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
 grant usage on schema auth to anon,authenticated,service_role;grant execute on function auth.uid() to anon,authenticated,service_role;
 create table public.profiles(id uuid primary key,nickname text,avatar_url text,reading_type text,discoverable boolean);
 create table public.member_settings(id uuid primary key,age integer,daily_goal integer,reading_answers jsonb,onboarded boolean);`);
 const root=path.join(__dirname,'..');
 await db.exec(fs.readFileSync(path.join(root,'supabase/sync.sql'),'utf8'));
 await db.exec(fs.readFileSync(path.join(root,'supabase/community.sql'),'utf8'));
 // 재실행해도 기존 데이터와 권한을 손상하지 않아요.
 await db.exec(fs.readFileSync(path.join(root,'supabase/community.sql'),'utf8'));
 const users=['00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000004'];
 for(const u of users)await db.query('insert into auth.users values($1)',[u]);
 const [a,b,mod,minor]=users;
 async function as(u,role=u?'authenticated':null){await db.exec('reset role');await db.query("select set_config('request.jwt.claim.sub',$1,false)",[u||'']);if(role)await db.exec('set role '+role);}
 async function rpc(action,data={}){return (await db.query('select public.ddok_community($1,$2::jsonb) as data',[action,JSON.stringify(data)])).rows[0].data;}
 async function deny(fn,why){await assert.rejects(fn);checks++;}
 for(const u of [a,b,mod]){await as(u);await rpc('confirm_age',{age_band:'14plus'});await rpc('accept_terms',{version:'2026-11-24.1'});}
 await as(null,'anon');await deny(()=>rpc('create_post',{kind:'자유',body:'안녕',visibility:0}),'guest write');
 await as(minor);await deny(()=>rpc('confirm_age',{age_band:'13'}),'age');await deny(()=>rpc('create_post',{kind:'자유',body:'안녕',visibility:0}),'no eligibility');
 await as(a);await db.query('insert into public.profiles(id,nickname,discoverable) values($1,$2,true)',[a,'독자A']);
 await deny(()=>db.query('insert into public.profiles(id,nickname) values($1,$2)',[b,'위조']),'profile owner');
 const first=(await rpc('create_post',{kind:'자유',body:'첫 글',visibility:0})).id;
 const privatePost=(await rpc('create_post',{kind:'자유',body:'비공개 글',visibility:2})).id;
 const friendPost=(await rpc('create_post',{kind:'자유',body:'친구 글',visibility:1})).id;
 await as(b);assert.equal((await rpc('feed')).length,1);checks++;
 await deny(()=>rpc('detail',{id:privatePost}),'private');await deny(()=>rpc('detail',{id:friendPost}),'not friends');
 await deny(()=>rpc('delete_post',{id:first}),'other post');await deny(()=>db.query('select * from public.ddok_reports'),'reports RLS');
 const comment=(await rpc('create_comment',{post_id:first,body:'댓글'})).id;
 await as(a);await deny(()=>rpc('delete_comment',{id:comment}),'other comment');
 await as(b);await rpc('edit_comment',{id:comment,post_id:first,body:'고친 댓글'});assert.equal((await rpc('detail',{id:first})).comments[0].body,'고친 댓글');checks++;
 const report=(await rpc('report',{target_type:'post',target_id:first,reason:'harassment',detail:'신고 내용'})).id;
 assert.equal((await rpc('report',{target_type:'post',target_id:first,reason:'harassment'})).id,report);checks++;
 await deny(()=>rpc('moderation_queue'),'not moderator');await deny(()=>db.query('insert into public.ddok_moderators values($1)',[b]),'self promote');
 await rpc('block',{user_id:a});assert.equal((await rpc('feed')).length,0);checks++;
 await as(a);await deny(()=>rpc('report',{target_type:'comment',target_id:comment,reason:'other'}),'blocked comment');
 await as(b);await rpc('unblock',{user_id:a});assert.equal((await rpc('feed')).length,1);checks++;
 await as(null);await db.query('insert into public.ddok_moderators values($1)',[mod]);
 await db.query('insert into public.profiles(id,nickname,discoverable) values($1,$2,true)',[mod,'운영 계정']);
 await as(b);const againstMod=(await rpc('report',{target_type:'user',target_id:mod,reason:'other'})).id;
 await as(mod);assert.equal((await rpc('moderation_queue')).length,1);checks++;
 await deny(()=>rpc('moderate',{report_id:againstMod,action:'dismiss',note:'내 신고 무효화 시도'}),'own report moderation');
 await rpc('moderate',{report_id:report,action:'hide',note:'규칙 위반 확인'});
 await as(b);assert.equal((await rpc('feed')).length,0);checks++;
 await deny(()=>rpc('detail',{id:first}),'hidden post');
 await as(mod);await rpc('moderate',{report_id:report,action:'restore',note:'추가 확인 후 복원'});
 await rpc('moderate',{report_id:report,action:'restrict',note:'반복 위반 제한'});
 await as(a);await deny(()=>rpc('create_post',{kind:'자유',body:'제한 우회',visibility:0}),'restriction');
 await as(mod);await rpc('moderate',{report_id:report,action:'release',note:'제한 해제'});
 await as(a);await rpc('edit_post',{id:first,body:'수정 글',kind:'자유',visibility:0});assert.equal((await rpc('detail',{id:first})).post.body,'수정 글');checks++;
 await deny(()=>rpc('create_post',{kind:'밸런스',body:'선택',visibility:0}),'missing poll');
 const poll=(await rpc('create_post',{kind:'밸런스',body:'선택',visibility:0,options:['A','B']})).id;
 await rpc('vote',{post_id:poll,choice:1});assert.deepEqual((await rpc('detail',{id:poll})).post.votes,[0,1]);checks++;
 await as(null,'anon');assert.ok((await rpc('feed')).length>=1);checks++;
 await as(null);await db.query('insert into public.ddok_friendships values($1,$2,true,now())',[a,b]);
 await as(b);assert.ok((await rpc('feed')).some(p=>p.id===friendPost));checks++;
 await as(mod);const cascadedReport=(await rpc('report',{target_type:'comment',target_id:comment,reason:'other'})).id;
 // 회원 삭제는 서비스 키만 준비할 수 있고, 완료 후에는 이전 JWT도 쓸 수 없어요.
 await deny(()=>db.query('select public.ddok_delete_prepare($1)',[a]),'delete other account');
 await as(null,'service_role');await db.query('select public.ddok_delete_prepare($1)',[a]);
 await as(a);await deny(()=>rpc('create_comment',{post_id:first,body:'삭제 중 저장'}),'deleting');
 await as(null);await db.query('delete from auth.users where id=$1',[a]);
 assert.equal((await db.query('select count(*)::int as n from public.profiles where id=$1',[a])).rows[0].n,0);checks++;
 assert.equal((await db.query('select count(*)::int as n from public.ddok_posts where author_id=$1',[a])).rows[0].n,0);checks++;
 assert.equal((await db.query('select count(*)::int as n from public.ddok_reports where subject_id=$1',[a])).rows[0].n,0);checks++;
 assert.equal((await db.query('select count(*)::int as n from public.ddok_reports where id=$1',[cascadedReport])).rows[0].n,0);checks++;
 await as(a);await deny(()=>rpc('confirm_age',{age_band:'14plus'}),'deleted JWT');
 await as(b);assert.equal((await rpc('feed')).length,0);checks++;
 await db.close();console.log(`PASS ${checks} permission, privacy, moderation and deletion checks`);
}
main().catch(e=>{console.error(e.message,e.cause||'');process.exitCode=1});
