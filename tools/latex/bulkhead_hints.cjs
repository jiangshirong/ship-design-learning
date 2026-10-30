const fs=require('fs');
function tokens(s){
 const out=[];let i=0;
 function group(k){let d=0;do{if(s[k]==='{')d++;if(s[k]==='}')d--;k++;}while(k<s.length&&d);return k;}
 while(i<s.length){
  if(s[i]==='@'){i=s.indexOf('@',i+1)+1;continue;}
  if(s[i]==='\\') {const m=s.slice(i).match(/^\\([A-Za-z]+|.)/);i+=m[0].length;if(['mathrm','text','mathtt','cssId'].includes(m[1])&&s[i]==='{')i=group(i);continue;}
  if(/[A-Za-z]/.test(s[i])){let a=i;i++;if(s.slice(a,a+2)==='DW')i++;
   const base=s.slice(a,i);let sub='';if(s[i]==='_'){i++;let st=i;if(s[i]==='{')i=group(i);else i++;sub=s.slice(st,i);}
   out.push({start:a,end:i,base,sub,tex:s.slice(a,i)});continue;
  }i++;
 }return out;
}
module.exports={tokens};
if(require.main===module){const data=JSON.parse(fs.readFileSync(process.argv[2],'utf8'));console.log([...new Set(Object.values(data).flatMap(v=>v.zh.flatMap(r=>tokens(r.tex).map(t=>t.tex))))].join('\n'));}

const registry=JSON.parse(fs.readFileSync(require('path').join(__dirname,'../../content/bulkhead_symbol_registry.json'),'utf8'));
module.exports.annotate=function(s,markers){
 let result='',last=0;
 for(const t of tokens(s)){
  const entry=registry[t.tex];if(!entry)throw Error('Unreviewed bulkhead symbol: '+t.tex);
  result+=s.slice(last,t.start);
  const b='term'+Object.keys(markers).length;markers[b]=entry.base_hint;
  result+=`\\cssId{${b}}{${t.base}}`;
  if(t.sub){const k='term'+Object.keys(markers).length;markers[k]=entry.hint;
   const inner=t.sub.startsWith('{')?t.sub.slice(1,-1):t.sub;
   result+=`_{\\cssId{${k}}{${inner}}}`;
  }last=t.end;
 }return result+s.slice(last);
};
