// Offline MathJax compiler. Runtime needs only path-based SVG and digit glyphs.
const fs=require('fs'),path=require('path'),crypto=require('crypto');
module.paths.push(path.resolve(__dirname,'../../../../tools/latex/node_modules'));
module.paths.push(path.join(process.env.LOCALAPPDATA||'', 'ShipLearningTools', 'node_modules'));
const {mathjax}=require('mathjax-full/js/mathjax.js');
const {TeX}=require('mathjax-full/js/input/tex.js');
const {SVG}=require('mathjax-full/js/output/svg.js');
const {liteAdaptor}=require('mathjax-full/js/adaptors/liteAdaptor.js');
const {RegisterHTMLHandler}=require('mathjax-full/js/handlers/html.js');
const {AllPackages}=require('mathjax-full/js/input/tex/AllPackages.js');
const opentype=require('opentype.js');
const {DOMParser}=require('@xmldom/xmldom');
const ROOT=path.resolve(__dirname,'../..'),EM=30;
const adaptor=liteAdaptor();RegisterHTMLHandler(adaptor);
const font=opentype.loadSync('C:/Windows/Fonts/times.ttf');
const output=new SVG({fontCache:'none'});
// Register real glyph metrics BEFORE layout. Replacing fallback <text> afterward
// retained MathJax's estimated 600-unit advances and undersized 884px outlines.
const texXHeight=output.font.getChar('normal',0x78)[0]*1000;
const cyrillicScale=texXHeight/font.charToGlyph('х').getMetrics().yMax;
const cyrillicChars={},cyrillicInk={};
for(const c of 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя'){
 const glyph=font.charToGlyph(c),m=glyph.getMetrics(),n=c.codePointAt(0);
 if(!glyph.index)throw Error('Missing Cyrillic glyph: '+c);
 const outline=glyph.getPath(0,0,font.unitsPerEm*cyrillicScale);
 // OpenType's screen path is y-down; MathJax glyph paths are y-up.
 for(const command of outline.commands)for(const key of ['y','y1','y2'])if(key in command)command[key]*=-1;
 const p=outline.toPathData(3);
 cyrillicChars[n]=[m.yMax*cyrillicScale/1000,-m.yMin*cyrillicScale/1000,glyph.advanceWidth*cyrillicScale/1000,{p:p.slice(1,-1)}];
 cyrillicInk[n]=[m.xMin*cyrillicScale,m.yMin*cyrillicScale,m.xMax*cyrillicScale,m.yMax*cyrillicScale];
}
output.font.defineChars('normal',cyrillicChars);
const doc=mathjax.document('',{InputJax:new TeX({packages:AllPackages,formatError:(_j,e)=>{throw e;}}),OutputJax:output});
const values=JSON.parse(fs.readFileSync(path.join(ROOT,'qa/formula-values.json'),'utf8'));
const sources=JSON.parse(fs.readFileSync(path.join(ROOT,'content/latex_source.json'),'utf8'));
const stabilityPath=path.join(ROOT,'content/stability_latex.json');
if(fs.existsSync(stabilityPath))Object.assign(sources,JSON.parse(fs.readFileSync(stabilityPath,'utf8')));
Object.assign(sources,JSON.parse(fs.readFileSync(path.join(ROOT,"../../content/bulkheads_latex.json"),"utf8")));
const topicPath=path.join(ROOT,'content/topics_latex.json');
if(fs.existsSync(topicPath))Object.assign(sources,JSON.parse(fs.readFileSync(topicPath,'utf8')));
Object.assign(sources,JSON.parse(fs.readFileSync(path.join(ROOT,'content/exam12/latex.json'),'utf8')));
const terms=JSON.parse(fs.readFileSync(path.join(ROOT,'content/notation_terms.json'),'utf8'));
const bases=JSON.parse(fs.readFileSync(path.join(ROOT,'content/notation_bases.json'),'utf8'));
let activeBulkhead=false;
let activeModule11=false;
let activeRevision9p=false;
const bhBases={L:'длина́\n船长或舱室长度；下标指明对象。',l:'длина́\n舱室长度；本章约定符号。',n:'число́ шпа́ций\n肋距间隔数。',a:'шпа́ция\n肋距；本章约定符号。',h:'высота́\n高度。',b:'шири́на\n宽度。'};
const multiply=(a,b)=>[a[0]*b[0]+a[2]*b[1],a[1]*b[0]+a[3]*b[1],a[0]*b[2]+a[2]*b[3],a[1]*b[2]+a[3]*b[3],a[0]*b[4]+a[2]*b[5]+a[4],a[1]*b[4]+a[3]*b[5]+a[5]];
function transform(s){
 let a=[1,0,0,1,0,0];
 for(const m of s.matchAll(/(translate|scale|matrix)\(([^)]+)\)/g)){
  const n=m[2].trim().split(/[\s,]+/).map(Number);
  const b=m[1]==='translate'?[1,0,0,1,n[0],n[1]||0]:m[1]==='scale'?[n[0],0,0,n[1]??n[0],0,0]:n;
  a=multiply(a,b);
 }return a;
}
function hoverBounds(svg,markers){
 const xml=new DOMParser().parseFromString(svg,'image/svg+xml'),bounds={};
 function walk(el,parent,key){
  if(el.nodeType!==1)return;
  const matrix=multiply(parent,transform(el.getAttribute('transform')||''));
  const own=el.getAttribute('id');if(markers[own])key=own;
  if(el.tagName==='path'&&key){
   const n=parseInt(el.getAttribute('data-c'),16),data=output.font.getChar('normal',n);
   if(!data)throw Error('Missing hover metrics: '+el.getAttribute('data-c'));
   const b0=cyrillicInk[n]||[0,-data[1]*1000,data[2]*1000,data[0]*1000];
   const points=[[b0[0],b0[1]],[b0[2],b0[1]],[b0[0],b0[3]],[b0[2],b0[3]]].map(([x,y])=>[matrix[0]*x+matrix[2]*y+matrix[4],matrix[1]*x+matrix[3]*y+matrix[5]]);
   const b=[Math.min(...points.map(p=>p[0])),Math.min(...points.map(p=>p[1])),Math.max(...points.map(p=>p[0])),Math.max(...points.map(p=>p[1]))];
   bounds[key]=bounds[key]?[Math.min(bounds[key][0],b[0]),Math.min(bounds[key][1],b[1]),Math.max(bounds[key][2],b[2]),Math.max(bounds[key][3],b[3])]:b;
  }
  for(let child=el.firstChild;child;child=child.nextSibling)walk(child,matrix,key);
 }walk(xml.documentElement,[1,0,0,1,0,0],null);
 return Object.entries(markers).map(([key,text])=>{
  if(!bounds[key])throw Error('Subscript has no measured glyphs: '+key);
  return {bounds:bounds[key],text};
 });
}
const annotateEnglish=require('../../../../tools/latex/english_hints.cjs');
function raw(tex){
 const markers={};
 let annotated;
 if(activeRevision9p){ annotated=require('./revision9p_hints.cjs')(tex,markers); }
 else if(activeModule11){ annotated=require('./module11_hints.cjs')(tex,markers); }
 else if(activeBulkhead){ annotated=require('../../../../tools/latex/bulkhead_hints.cjs').annotate(tex,markers); }else{
 annotated=tex.replace(/(\\[a-zA-Z]+|[A-Za-z])_\{\\(?:text|mathrm)\{([А-Яа-яЁё.0-9 ]+)\}/g,(all,base,suffix)=>{
  const text=terms[base+'|'+suffix];if(!text)throw Error('Missing Russian expansion: '+base+'|'+suffix);
  const id='term'+Object.keys(markers).length;markers[id]=suffix+'\n'+text;
  const baseId='term'+Object.keys(markers).length;markers[baseId]=(base==='\\mu'?'μ':base)+'\n'+((activeBulkhead?bhBases[base]:null)||bases[base]||'обозначе́ние\n约定符号');
  return `\\cssId{${baseId}}{${base}}_{\\cssId{${id}}{\\text{${suffix}}}`;
 });
 annotated=annotateEnglish(annotated,markers);
 }
 const container=doc.convert(annotated,{display:true});
 let svg=adaptor.outerHTML(adaptor.firstChild(container));
 if(/data-mml-node="merror"/.test(svg))throw Error('MathJax error: '+tex);
 const hover=hoverBounds(svg,markers);
 // cssId emits empty alignment markers; actual glyphs must already be paths.
 svg=svg.replace(/<text[^>]*><\/text>/g,'');
 if(svg.includes('<text'))throw Error('Unregistered fallback glyph: '+tex);
 const box=svg.match(/viewBox="([^"]+)"/)[1].split(' ').map(Number);
 return {svg,box,hover};
}
const glyphs={};
for(const c of '0123456789.,-'){
 const {svg,box}=raw('\\mathtt{'+c+'}');
 const outer=svg.match(/<g stroke=[^>]*>([\s\S]*)<\/g><\/svg>/)[1];
 glyphs[c]={body:outer,width:box[2]};
}
function slotSize(key){
	if(key.startsWith('ex_'))return 9;
	if(key.startsWith('y_'))return 7;
	if(key.startsWith('m11_'))return 8;
 if(key.startsWith('st_')||key.startsWith('bh_'))return 8;
 if(['xg','zg'].includes(key))return 4;
 const num=Number(values[key]);if(!Number.isFinite(num))throw Error('Missing value: '+key);
 return String(Math.ceil(num)).length;
}
function replaceGroup(svg,id,token){
 const start=svg.indexOf(`id="${id}"`);if(start<0)throw Error('Missing slot '+id);
 const inner=svg.indexOf('>',start)+1;const tag=/<\/?g\b[^>]*>/g;tag.lastIndex=inner;
 let level=1,m;while((m=tag.exec(svg))){level+=m[0].startsWith('</')?-1:1;if(!level){const align=svg.slice(inner,m.index).match(/data-idbox="true" transform="([^"]+)"/);if(align)token=`<g transform="${align[1]}">${token}</g>`;return svg.slice(0,inner)+token+svg.slice(m.index);}}
 throw Error('Unclosed slot');
}
const assets={};
function compile(tex){
 const id=crypto.createHash('sha256').update((activeRevision9p?'R9:':activeBulkhead?'BH:audit-v2:':activeModule11?'M11:':'')+tex).digest('hex').slice(0,20);if(assets[id])return id;
 const slots=[];
 const withSlots=tex.replace(/@([\w]+)@/g,(_,key)=>{const count=slotSize(key),name='slot'+slots.length;slots.push({key,name,width:count*glyphs['0'].width});return `\\cssId{${name}}{\\mathtt{${'0'.repeat(count)}}}`;});
 let {svg,box,hover}=raw(withSlots);
 for(const slot of slots)svg=replaceGroup(svg,slot.name,'@@'+slot.name+'@@');
 const pad=70;box=[box[0]-pad,box[1]-pad,box[2]+2*pad,box[3]+2*pad];
 const w=box[2]*EM/1000,h=box[3]*EM/1000;
 svg=svg.replace(/width="[\d.]+ex"/,`width="${w}"`).replace(/height="[\d.]+ex"/,`height="${h}"`).replace(/viewBox="[^"]+"/,`viewBox="${box.join(' ')}"`).replaceAll('currentColor','#dbeaf2');
 if(svg.includes('<text'))throw Error('SVG text remains: '+tex);
 const hints=hover.map(({bounds:b,text})=>({text,rect:[(b[0]-box[0])*EM/1000,(b[1]-box[1])*EM/1000,(b[2]-b[0])*EM/1000,(b[3]-b[1])*EM/1000]}));
 assets[id]={tex,svg,slots,hints,width:w,height:h,baseline:-box[1]*EM/1000};return id;
}
function split(tex,operators){
 const pieces=[];let start=0,depth=0;let m;
 const tokens=/\\(?:approx|le|ge|longrightarrow|propto)\b|[{}()[\]=+\-]/g;
 while((m=tokens.exec(tex))){const t=m[0];if(['{','(','['].includes(t))depth++;else if(['}',')',']'].includes(t))depth--;else if(!depth&&operators.includes(t)&&m.index>start){pieces.push(tex.slice(start,m.index).trim());start=m.index;}}
 pieces.push(tex.slice(start).trim());return pieces.filter(Boolean);
}
function fragments(tex){
 const id=compile(tex);if(assets[id].width<=300)return [id];
 let parts=split(tex,['=',String.raw`\approx`,String.raw`\le`,String.raw`\ge`,String.raw`\longrightarrow`,String.raw`\propto`]);
 if(parts.length===1)parts=split(tex,['+','-']);
 if(parts.length===1)return[id];
 return parts.flatMap(p=>{const child=compile(p);return assets[child].width>300?split(p,['+','-']).map(compile):[child];});
}
const lessons={};
for(const [id,languages] of Object.entries(sources)){
 activeBulkhead=id.startsWith("BH:");activeModule11=id.startsWith("M11:");activeRevision9p=id.startsWith("R9:");lessons[id]={};
 for(const [lang,rows] of Object.entries(languages))lessons[id][lang]=rows.map(row=>({...row,full:compile(row.tex),pieces:fragments(row.tex)}));
}
const typography={cyrillic_font:'Times New Roman',layout:'registered glyph metrics before MathJax layout',x_height:texXHeight/1000,cyrillic_scale:cyrillicScale,glyphs:Object.fromEntries(Object.entries(cyrillicChars).map(([n,v])=>[String.fromCodePoint(+n),{height:v[0],depth:v[1],advance:v[2]}]))};
const out={renderer:'MathJax 3.2.2 SVG',em:EM,typography,glyphs,assets,lessons};
fs.writeFileSync(path.join(ROOT,'content/latex_assets.json'),JSON.stringify(out));
fs.writeFileSync(path.join(ROOT,'qa/latex-build.json'),JSON.stringify({renderer:out.renderer,steps:Object.keys(lessons).filter(id=>!id.startsWith('_')).length,diagram_formulas:Object.keys(lessons).filter(id=>id.startsWith('_')).length,assets:Object.keys(assets).length,svg_text_nodes:0,max_width:Math.max(...Object.values(assets).map(a=>a.width))},null,2));
console.log('MathJax compiled',Object.keys(assets).length,'SVG assets for',Object.keys(lessons).length,'steps');
