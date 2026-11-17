// 카카오 인증과 가입 정보는 로컬 개발 서버에서 처리해요.
const http=require('http'),fs=require('fs'),path=require('path'),crypto=require('crypto');
const dir=path.join(process.env.LOCALAPPDATA||require('os').homedir(),'DDOKDOK','local-auth');
fs.mkdirSync(dir,{recursive:true});
const configFile=path.join(dir,'kakao-config.json'),usersFile=path.join(dir,'kakao-users.json');
const origin='http://localhost:5174',redirectUri=origin+'/auth/kakao/callback';
const sessions=new Map(),states=new Map(),random=()=>crypto.randomBytes(32).toString('hex');
function config(){const c=fs.existsSync(configFile)?JSON.parse(fs.readFileSync(configFile,'utf8')):{};return {key:process.env.KAKAO_REST_API_KEY||c.restApiKey,secret:process.env.KAKAO_CLIENT_SECRET||c.clientSecret};}
function users(){return fs.existsSync(usersFile)?JSON.parse(fs.readFileSync(usersFile,'utf8')):{};}
function cookie(req,name){const x=(req.headers.cookie||'').split(';').map(x=>x.trim()).find(x=>x.startsWith(name+'='));return x?x.slice(name.length+1):'';}
function session(req){const id=cookie(req,'ddok_session'),s=sessions.get(id);if(s&&s.expires>Date.now())return s;sessions.delete(id);return null;}
function json(res,status,data){res.writeHead(status,{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});res.end(JSON.stringify(data));}
function redirect(res,url,cookies){res.writeHead(302,{Location:url,'Cache-Control':'no-store',...(cookies?{'Set-Cookie':cookies}:{})});res.end();}
async function auth(req,res){
 const u=new URL(req.url,origin);
 if(req.headers.host!=='localhost:5174'){json(res,400,{error:'localhost 주소로 다시 열어 주세요.'});return;}
 if(u.pathname==='/auth/kakao/start'&&req.method==='GET'){
  const c=config();if(!c.key){json(res,503,{error:'카카오 연결 설정을 확인해 주세요.'});return;}
  const state=random();states.set(state,Date.now()+600000);
  const q=new URLSearchParams({client_id:c.key,redirect_uri:redirectUri,response_type:'code',state});
  redirect(res,'https://kauth.kakao.com/oauth/authorize?'+q,['ddok_oauth='+state+'; HttpOnly; SameSite=Lax; Path=/auth/kakao; Max-Age=600']);return;
 }
 if(u.pathname==='/auth/kakao/callback'&&req.method==='GET'){
  const state=u.searchParams.get('state'),expires=states.get(state);states.delete(state);
  const clear='ddok_oauth=; HttpOnly; SameSite=Lax; Path=/auth/kakao; Max-Age=0';
  if(!state||state!==cookie(req,'ddok_oauth')||!expires||expires<Date.now()){redirect(res,'/?kakao=expired',[clear]);return;}
  if(u.searchParams.has('error')){redirect(res,'/?kakao=cancelled',[clear]);return;}
  const code=u.searchParams.get('code');if(!code||code.length>2048){redirect(res,'/?kakao=failed',[clear]);return;}
  try{
   const c=config(),body=new URLSearchParams({grant_type:'authorization_code',client_id:c.key,redirect_uri:redirectUri,code});if(c.secret)body.set('client_secret',c.secret);
   const t=await fetch('https://kauth.kakao.com/oauth/token',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded;charset=utf-8'},body,signal:AbortSignal.timeout(15000)});
   const token=await t.json();if(!t.ok||!token.access_token)throw Error('token');
   const r=await fetch('https://kapi.kakao.com/v2/user/me',{headers:{Authorization:'Bearer '+token.access_token},signal:AbortSignal.timeout(15000)});
   const p=await r.json();if(!r.ok||!p.id)throw Error('profile');
   const id=String(p.id),saved=users()[id],sid=random();
   sessions.set(sid,{id,nickname:saved?.nickname||p.kakao_account?.profile?.nickname||'',profile:saved||null,expires:Date.now()+86400000});
   redirect(res,'/?kakao=success',[clear,'ddok_session='+sid+'; HttpOnly; SameSite=Lax; Path=/; Max-Age=86400']);
  }catch{redirect(res,'/?kakao=failed',[clear]);}return;
 }
 if(u.pathname==='/auth/kakao/session'&&req.method==='GET'){
  const s=session(req);json(res,200,s?{authenticated:true,onboarded:!!s.profile,profile:s.profile||{nickname:s.nickname}}:{authenticated:false});return;
 }
 if(u.pathname==='/auth/kakao/complete'&&req.method==='POST'){
  if(req.headers.origin!==origin){json(res,403,{error:'다시 로그인해 주세요.'});return;}
  const s=session(req);if(!s){json(res,401,{error:'다시 로그인해 주세요.'});return;}
  let raw='';for await(const chunk of req){raw+=chunk;if(raw.length>4096){json(res,413,{error:'입력 내용을 확인해 주세요.'});return;}}
  let d;try{d=JSON.parse(raw)}catch{json(res,400,{error:'입력 내용을 확인해 주세요.'});return;}
  const nickname=typeof d.nickname==='string'?d.nickname.trim():'',goal=d.goal,answers=d.answers;
  if(!nickname||[...nickname].length>10||!Number.isInteger(goal)||goal<1||goal>300||!Array.isArray(answers)||answers.length!==4||!answers.every(x=>x===null||Number.isInteger(x)&&x>=0&&x<=3)){
   json(res,400,{error:'닉네임과 독서 목표를 확인해 주세요.'});return;
  }
  const db=users();s.profile={nickname,goal,answers};db[s.id]=s.profile;
  fs.writeFileSync(usersFile+'.tmp',JSON.stringify(db),{mode:0o600});fs.renameSync(usersFile+'.tmp',usersFile);
  json(res,200,{ok:true});return;
 }
 json(res,404,{error:'연결 주소를 확인해 주세요.'});
}
const createServer=http.createServer;
http.createServer=function(listener){return createServer.call(http,(req,res)=>{
 if(req.url.split('?')[0].startsWith('/auth/kakao/'))auth(req,res).catch(()=>{if(!res.headersSent)json(res,500,{error:'잠시 후 다시 연결해 주세요.'});else res.end()});
 else listener(req,res);
});};
setInterval(()=>{for(const[k,v]of states)if(v<Date.now())states.delete(k);for(const[k,v]of sessions)if(v.expires<Date.now())sessions.delete(k);},60000).unref();
process.env.PORT='5174';process.argv.push('--local');require('./dev-server.js');
