const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const text=fs.readFileSync(path.join(__dirname,'../Reading_app.html'),'utf8');
const scripts=[...text.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g)];
scripts.forEach((m,i)=>new vm.Script(m[1],{filename:'Reading_app.html:script-'+i}));
console.log(`PASS ${scripts.length} inline scripts compile`);
