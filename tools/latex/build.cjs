// Offline MathJax compiler. Runtime needs only path-based SVG and digit glyphs.
const fs=require('fs'),path=require('path'),crypto=require('crypto');
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
const terms=JSON.parse(fs.readFileSync(path.join(ROOT,'content/notation_terms.json'),'utf8'));
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
const annotateEnglish=require('./english_hints.cjs');
const bases={...require('../../modules/review/content/notation_bases.json'),F:'су́мма зави́симых масс\n本章为随设计参数与排水量变化的质量函数。',S:'пло́щадь\n面积。',n:'но́мер / число́\n本步骤的计数或迭代编号。',k:'коэффицие́нт\n修正系数；下标区分适用对象。'};
function raw(tex){
 const markers={};
 let annotated=tex.replace(/(\\[a-zA-Z]+|[A-Za-z])_\{\\(?:text|mathrm)\{([А-Яа-яЁё.]+)\}/g,(all,base,suffix)=>{
  const text=terms[base+'|'+suffix];if(!text)throw Error('Missing Russian expansion: '+base+'|'+suffix);
  const id='term'+Object.keys(markers).length;markers[id]=text;
  const baseId='term'+Object.keys(markers).length;markers[baseId]=(base==='g'&&['ст','об'].includes(suffix))?'коэффицие́нт ма́ссы\n本式的质量估算系数，不能按重力加速度理解。':(base==='\\eta'&&suffix==='Н')?'коэффицие́нт Но́рмана\n排水量增量与直接质量增量的近似比值。':bases[base]||text;
  return `\\cssId{${baseId}}{${base}}_{\\cssId{${id}}{\\text{${suffix}}}`;
 });
 annotated=annotateEnglish(annotated,markers);
 const approximationSymbols={
  '\\zeta_f':'коэффицие́нт тре́ния\n摩擦阻力系数；f是资料中的摩擦项标记。',
  '\\zeta_n':'надба́вка на шерохова́тость\n船壳粗糙度附加系数。',
  '\\zeta_a':'выступа́ющие ча́сти\n附体阻力系数。',
  '\\zeta_r':'оста́точное сопротивле́ние\n剩余阻力系数。',
  '\\alpha_{\\Psi_0}':'попра́вка для станда́ртной длины́\n标准相对长度对应的查图修正值。',
  '\\alpha_\\Psi':'попра́вка для относи́тельной длины́\n本船相对长度对应的查图修正值。',
  'k_\\Psi':'коэффицие́нт относи́тельной длины́\n两次查图修正值之比。',
  'k_{B/T}':'попра́вка по B/T\n宽吃水比修正项：按对应弗劳德数曲线查图。',
  '\\alpha_{B/T}':'попра́вка по B/T\n宽吃水比修正项：与k项相乘使用。',
  '\\Psi_0':'станда́ртная относи́тельная длина́\n图表系列的标准相对长度；0不是本船。',
  '\\Psi':'относи́тельная длина́\n船长除以排水体积的立方根，无量纲。',
  '\\Omega':'смо́ченная пове́рхность\n船壳水下湿表面积，单位平方米。',
  '\\nu':'кинемати́ческая вя́зкость\n运动黏度，单位平方米每秒。',
  'EPS':'буксиро́вочная мо́щность\n拖曳功率，等于阻力乘航速。',
  'Re':'число́ Ре́йнольдса\n雷诺数，用于查摩擦阻力系数。',
  'Fr':'число́ Фру́да\n弗劳德数，用于选择剩余阻力曲线。'
 };
 const symbolPattern=new RegExp(Object.keys(approximationSymbols).map(s=>s.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')).join('|'),'g');
 annotated=annotated.replace(symbolPattern,s=>{const id='term'+Object.keys(markers).length;markers[id]=approximationSymbols[s];return `\\cssId{${id}}{${s}}`;});
 // The teacher's first-approximation template uses Latin Z_g, not Cyrillic z_г.
 annotated=annotated.replace(/Z_(g|\{g0\})/g,(_all,suffix)=>{
  const baseId='term'+Object.keys(markers).length;
  markers[baseId]='апплика́та це́нтра масс\n重心高度：从基本平面量起；Z是坐标约定符号。';
  const subId='term'+Object.keys(markers).length;
  markers[subId]='це́нтр ма́сс\n'+(suffix==='g'?'g表示全船重心；不是一个俄语词的首字母缩写。':'g表示全船重心，0表示母型船。');
  return `\\cssId{${baseId}}{Z}_{\\cssId{${subId}}{${suffix==='g'?'g':'g0'}}}`;
 });
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
 const decimals=['q','pfcoef'].includes(key)?12:['pk','pe','Fr','delta','alpha'].includes(key)?8:4;
 const num=Number(values[key]);if(!Number.isFinite(num))throw Error('Missing value: '+key);
 return Math.max(7,num.toFixed(decimals).length+1);
}
function replaceGroup(svg,id,token){
 const start=svg.indexOf(`id="${id}"`);if(start<0)throw Error('Missing slot '+id);
 const inner=svg.indexOf('>',start)+1;const tag=/<\/?g\b[^>]*>/g;tag.lastIndex=inner;
 let level=1,m;while((m=tag.exec(svg))){level+=m[0].startsWith('</')?-1:1;if(!level){const align=svg.slice(inner,m.index).match(/data-idbox="true" transform="([^"]+)"/);if(align)token=`<g transform="${align[1]}">${token}</g>`;return svg.slice(0,inner)+token+svg.slice(m.index);}}
 throw Error('Unclosed slot');
}
const assets={};
function compile(tex){
 const id=crypto.createHash('sha256').update(tex).digest('hex').slice(0,20);if(assets[id])return id;
 const slots=[];
 const withSlots=tex.replace(/@([\w]+)@/g,(_,key)=>{const count=slotSize(key),name='slot'+slots.length;slots.push({key,name,width:(count-1)*glyphs['0'].width+glyphs['-'].width});return `\\cssId{${name}}{\\mathtt{-${'0'.repeat(count-6)}.0000}}`;});
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
 const tokens=/\\(?:approx|le|ge|longrightarrow|propto)(?![A-Za-z])|[{}()[\]=+<>\-]/g;
 while((m=tokens.exec(tex))){const t=m[0];if(['{','(','['].includes(t))depth++;else if(['}',')',']'].includes(t))depth--;else if(!depth&&operators.includes(t)&&m.index>start){pieces.push(tex.slice(start,m.index).trim());start=m.index;}}
 pieces.push(tex.slice(start).trim());return pieces.filter(Boolean);
}
function fragments(tex){
 const id=compile(tex);if(assets[id].width<=300)return [id];
 let parts=split(tex,['=','<','>',String.raw`\approx`,String.raw`\le`,String.raw`\ge`,String.raw`\longrightarrow`,String.raw`\propto`]);
 if(parts.length===1)parts=split(tex,['+','-']);
 if(parts.length===1)return[id];
 return parts.flatMap(p=>{const child=compile(p);return assets[child].width>300?split(p,['+','-']).map(compile):[child];});
}
const lessons={};
for(const [id,languages] of Object.entries(sources)){
 lessons[id]={};
 for(const [lang,rows] of Object.entries(languages))lessons[id][lang]=rows.map(row=>({...row,full:compile(row.tex),pieces:fragments(row.tex)}));
}
const typography={cyrillic_font:'Times New Roman',layout:'registered glyph metrics before MathJax layout',x_height:texXHeight/1000,cyrillic_scale:cyrillicScale,glyphs:Object.fromEntries(Object.entries(cyrillicChars).map(([n,v])=>[String.fromCodePoint(+n),{height:v[0],depth:v[1],advance:v[2]}]))};
const out={renderer:'MathJax 3.2.2 SVG',em:EM,typography,glyphs,assets,lessons};
fs.writeFileSync(path.join(ROOT,'content/latex_assets.json'),JSON.stringify(out));
fs.writeFileSync(path.join(ROOT,'qa/latex-build.json'),JSON.stringify({renderer:out.renderer,steps:Object.keys(lessons).filter(id=>!id.startsWith('_')).length,diagram_formulas:Object.keys(lessons).filter(id=>id.startsWith('_')).length,assets:Object.keys(assets).length,svg_text_nodes:0,max_width:Math.max(...Object.values(assets).map(a=>a.width))},null,2));
console.log('MathJax compiled',Object.keys(assets).length,'SVG assets for',Object.keys(lessons).length,'steps');
