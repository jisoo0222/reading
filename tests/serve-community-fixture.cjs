// 브라우저 검증용 로컬 서버예요. 실제 Supabase와 사용자 계정에 연결하지 않아요.
const fs=require('node:fs'),path=require('node:path'),http=require('node:http');
const {PGlite}=require(process.argv[2]||'@electric-sql/pglite');
const root=path.join(__dirname,'..'),port=5199;
async function start(){const db=new PGlite();
 await db.exec(`create role anon;create role authenticated;create role service_role bypassrls;create schema auth;create table auth.users(id uuid primary key);
 create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
 grant usage on schema auth to anon,authenticated,service_role;grant execute on function auth.uid() to anon,authenticated,service_role;
 create table public.profiles(id uuid primary key,nickname text,avatar_url text,reading_type text,discoverable boolean);
 create table public.member_settings(id uuid primary key,age integer,daily_goal integer,reading_answers jsonb,onboarded boolean);`);
 await db.exec(fs.readFileSync(path.join(root,'supabase/sync.sql'),'utf8'));await db.exec(fs.readFileSync(path.join(root,'supabase/community.sql'),'utf8'));
 const a='00000000-0000-0000-0000-000000000001',b='00000000-0000-0000-0000-000000000002',mod='00000000-0000-0000-0000-000000000003';
 for(const [id,name] of [[a,'검증용 독자A'],[b,'검증용 독자B'],[mod,'검증용 운영자']]){
  await db.query('insert into auth.users values($1)',[id]);await db.query('insert into public.ddok_eligibility(user_id,version) values($1,$2)',[id,'2026-11-24.1']);await db.query('insert into public.profiles values($1,$2,null,$3,true)',[id,name,'FADI']);}
 await db.query('insert into public.ddok_moderators values($1)',[mod]);
 await db.query('insert into public.ddok_community_terms(user_id,version) values($1,$2),($3,$2)',[b,'2026-11-24.1',mod]);
 await db.query('insert into public.ddok_posts(author_id,kind,body,visibility,book_id,book_title,book_author) values($1,$2,$3,0,6,$4,$5)',[b,'자유','검증용 게시글이에요. 실제 서비스 데이터가 아니에요.','날개','김해경(이상)']);
 let chain=Promise.resolve();
 const server=http.createServer((req,res)=>{chain=chain.catch(()=>{}).then(async()=>{
  res.setHeader('Cache-Control','no-store');
  if(req.url==='/'||req.url==='/Reading_app.html'){
   let html=fs.readFileSync(path.join(root,'Reading_app.html'),'utf8');const index=html.lastIndexOf('sbBootstrap();');
   const fixture=`sessionStorage.setItem(DDOK_AGE_KEY,'14plus');SB_CONFIG.url='http://127.0.0.1:${port}';SB_CONFIG.key='test-only';SB_SESSION={access_token:'test-A',refresh_token:'test-refresh',expires_at:9999999999,user:{id:'${a}'}};AUTH_SESSION={signedIn:true,provider:'supabase'};ME='검증용 독자A';MEP='';window.TEST_USERS={A:'${a}',B:'${b}',M:'${mod}'};community();`;
   html=html.slice(0,index)+fixture+html.slice(index+'sbBootstrap();'.length);res.setHeader('Content-Type','text/html;charset=utf-8');res.end(html);return;
  }
  if(req.url==='/__state'){await db.exec('reset role');const r=await db.query("select (select count(*) from public.ddok_reports)::int reports,(select count(*) from public.ddok_blocks)::int blocks,(select count(*) from public.ddok_posts)::int posts");res.setHeader('Content-Type','application/json');res.end(JSON.stringify(r.rows[0]));return;}
  if(req.url==='/auth/v1/user'){res.setHeader('Content-Type','application/json');res.end(JSON.stringify({id:a,last_sign_in_at:new Date().toISOString()}));return;}
  if(req.url==='/functions/v1/delete-account'){res.statusCode=503;res.setHeader('Content-Type','application/json');res.end(JSON.stringify({code:'deletion_not_ready'}));return;}
  if(req.url==='/rest/v1/rpc/ddok_community'){
   let raw='';for await(const part of req){raw+=part;if(raw.length>2000000)throw Error('large test payload')}
   const input=JSON.parse(raw),token=req.headers.authorization||'',uid=token==='Bearer test-A'?a:token==='Bearer test-B'?b:token==='Bearer test-M'?mod:'';
   await db.exec('reset role');await db.query("select set_config('request.jwt.claim.sub',$1,false)",[uid]);await db.exec('set role '+(uid?'authenticated':'anon'));
   try{const r=await db.query('select public.ddok_community($1,$2::jsonb) data',[input.p_action,JSON.stringify(input.p_data||{})]);res.setHeader('Content-Type','application/json');res.end(JSON.stringify(r.rows[0].data))}
   catch(e){res.statusCode=e.code==='42501'?403:400;res.setHeader('Content-Type','application/json');res.end(JSON.stringify({code:e.code,message:e.message}))}return;
  }
  res.statusCode=404;res.end();
 }).catch(e=>{res.statusCode=500;res.end(JSON.stringify({message:e.message}))})});
 server.listen(port,'127.0.0.1',()=>console.log('Community browser fixture: http://127.0.0.1:'+port));
 process.on('SIGINT',()=>server.close(async()=>{await db.close();process.exit()}));
}
start().catch(e=>{console.error(e);process.exitCode=1});
