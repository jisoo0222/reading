const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const {stripTypeScriptTypes}=require('node:module');
const source=stripTypeScriptTypes(fs.readFileSync(path.join(__dirname,'../supabase/functions/delete-account/index.ts'),'utf8'));
const uid='00000000-0000-0000-0000-000000000001';
async function app(options={}){
 let handler,calls=[];
 const fetch=async(url,opts={})=>{calls.push({url,opts});
  if(url.endsWith('/auth/v1/user'))return new Response(JSON.stringify({id:uid,last_sign_in_at:new Date(Date.now()-(options.old?3600000:1000)).toISOString()}),{status:options.invalid?401:200});
  if(url.endsWith('/rpc/ddok_delete_prepare'))return new Response(JSON.stringify({files:options.files||[]}),{status:options.prepareFailed?503:200});
  if(url.includes('/storage/v1/object/'))return new Response('[]',{status:options.storageFailed?500:200});
  if(url.includes('/auth/v1/admin/users/'))return new Response('{}',{status:options.deleteFailed?500:200});
  throw Error('Unexpected endpoint');
 };
 vm.runInNewContext(source,{Deno:{env:{get:k=>({SUPABASE_URL:'https://test.supabase.co',SUPABASE_SERVICE_ROLE_KEY:'test-secret'}[k])},serve:fn=>handler=fn},fetch,Request,Response,AbortSignal,Map,Set,JSON,Date,Number,Error});
 return {run:async(body={confirmation:'탈퇴'},headers={},method='POST')=>handler(new Request('https://test/functions/v1/delete-account',{method,headers:{origin:'https://jisoo0222.github.io',authorization:'Bearer user-token','content-type':'application/json',...headers},...(method==='OPTIONS'?{}:{body:JSON.stringify(body)})})),calls};
}
(async()=>{
 let a=await app();let r=await a.run({}, {},'OPTIONS');assert.equal(r.status,204);assert.equal(a.calls.length,0);
 a=await app();r=await a.run({confirmation:'탈퇴',user_id:'another-user'});assert.equal(r.status,400);assert.equal(a.calls.length,0);
 a=await app();r=await a.run(null);assert.equal(r.status,400);assert.equal(a.calls.length,0);
 a=await app();r=await a.run([]);assert.equal(r.status,400);assert.equal(a.calls.length,0);
 a=await app();r=await a.run({confirmation:'탈퇴'},{authorization:''});assert.equal(r.status,401);assert.equal(a.calls.length,0);
 a=await app();r=await a.run({confirmation:'탈퇴'},{origin:'https://attacker.test'});assert.equal(r.status,403);assert.equal(a.calls.length,0);
 a=await app({invalid:true});assert.equal((await a.run()).status,401);assert.equal(a.calls.length,1);
 a=await app({old:true});assert.equal((await a.run()).status,403);assert.equal(a.calls.length,1);
 a=await app({prepareFailed:true});assert.equal((await a.run()).status,503);assert.equal(a.calls.length,2);
 a=await app({files:[{bucket:'avatars',name:uid+'/photo.png'}],storageFailed:true});assert.equal((await a.run()).status,503);assert.equal(a.calls.some(c=>c.url.includes('/admin/users/')),false);
 a=await app({files:[{bucket:'avatars',name:uid+'/photo.png'}]});r=await a.run();assert.equal(r.status,200);assert.equal((await r.json()).deleted,true);assert.deepEqual(a.calls.map(c=>c.url),['https://test.supabase.co/auth/v1/user','https://test.supabase.co/rest/v1/rpc/ddok_delete_prepare','https://test.supabase.co/storage/v1/object/avatars','https://test.supabase.co/auth/v1/admin/users/'+uid]);
 assert.equal(a.calls[2].opts.method,'DELETE');assert.deepEqual(JSON.parse(a.calls[2].opts.body),{prefixes:[uid+'/photo.png']});
 a=await app({deleteFailed:true});r=await a.run();assert.equal(r.status,503);assert.equal((await r.json()).deleted,undefined);
 console.log('PASS 12 deletion authentication, ordering, failure and CORS cases');
})().catch(e=>{console.error(e);process.exitCode=1});
