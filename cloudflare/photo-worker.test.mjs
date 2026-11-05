// Security tests for photo-worker.js. Run: node cloudflare/photo-worker.test.mjs
// Signs real RS256 tokens with a throwaway key and uses an in-memory KV.
import worker from './photo-worker.js';
const { subtle } = globalThis.crypto;
const kp = await subtle.generateKey({name:'RSASSA-PKCS1-v1_5',modulusLength:2048,publicExponent:new Uint8Array([1,0,1]),hash:'SHA-256'},true,['sign','verify']);
const pub = await subtle.exportKey('jwk', kp.publicKey); pub.kid='k1'; pub.alg='RS256'; pub.use='sig';
globalThis.fetch = async () => new Response(JSON.stringify({keys:[pub]}));
const b64 = (b) => Buffer.from(b).toString('base64url');
async function token(claims, kid='k1'){ const h=b64(JSON.stringify({alg:'RS256',kid})), p=b64(JSON.stringify(claims));
  const sig=await subtle.sign('RSASSA-PKCS1-v1_5',kp.privateKey,new TextEncoder().encode(h+'.'+p)); return `${h}.${p}.${b64(new Uint8Array(sig))}`; }
const store=new Map();
const env={FIREBASE_PROJECT_ID:'alu-campus-fix',KV:{put:async(k,v,o)=>store.set(k,{v,m:o.metadata}),getWithMetadata:async k=>store.has(k)?{value:new Blob([store.get(k).v]).stream(),metadata:store.get(k).m}:{value:null,metadata:null},delete:async k=>store.delete(k)}};
const now=Math.floor(Date.now()/1000);
const good={aud:'alu-campus-fix',iss:'https://securetoken.google.com/alu-campus-fix',sub:'uidA',iat:now,exp:now+3600,email_verified:true};
const path='/photos/incidents/uidA/abc_1.jpg', base='https://w.dev';
const req=(m,p,t,body)=>new Request(base+p,{method:m,headers:{...(t?{authorization:'Bearer '+t}:{}),'content-type':'image/jpeg'},body});
const cases=[
 ['upload ok', req('POST',path,await token(good),new Uint8Array([1,2,3])),201],
 ['get ok', req('GET',path),200],
 ['no token', req('POST',path,null,new Uint8Array([1])),401],
 ['other user folder', req('POST','/photos/incidents/uidB/x.jpg',await token(good),new Uint8Array([1])),403],
 ['unverified', req('POST',path,await token({...good,email_verified:false}),new Uint8Array([1])),403],
 ['wrong project', req('POST',path,await token({...good,aud:'evil'}),new Uint8Array([1])),401],
 ['expired', req('POST',path,await token({...good,exp:now-10}),new Uint8Array([1])),401],
 ['tampered', req('POST',path,(await token(good)).slice(0,-4)+'AAAA',new Uint8Array([1])),401],
 ['bad path', req('GET','/photos/incidents/uidA/x.png'),400],
 ['too big', req('POST',path,await token(good),new Uint8Array(5*1024*1024+1)),413],
 ['delete other', req('DELETE',path,await token({...good,sub:'uidB'})),403],
 ['delete ok', req('DELETE',path,await token(good)),200],
 ['gone', req('GET',path),404],
];
let fail=0; for (const [n,r,exp] of cases){ const res=await worker.fetch(r,env); const ok=res.status===exp; if(!ok)fail++; console.log((ok?'PASS':'FAIL'),n,res.status, ok?'':await res.text()); }
console.log(fail? fail+' FAILED':'ALL PASSED');
if (fail) process.exit(1);
