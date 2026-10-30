const fs=require('fs'),path=require('path');
const root=path.resolve(__dirname,'..');
const {tokens}=require('../tools/latex/bulkhead_hints.cjs');
const registry=JSON.parse(fs.readFileSync(path.join(root,'content/bulkhead_symbol_registry.json')));
const formulas=JSON.parse(fs.readFileSync(path.join(root,'content/bulkheads_latex.json')));
const bundle=JSON.parse(fs.readFileSync(path.join(root,'modules/review/content/latex_assets.json')));
const used=new Set();let rows=0,hits=0;
for(const [id,langs] of Object.entries(formulas))for(const [lang,records] of Object.entries(langs))for(let i=0;i<records.length;i++){
 const row=records[i],ts=tokens(row.tex);rows++;
 for(const t of ts){if(!registry[t.tex])throw Error(t.tex);used.add(t.tex);}
 const entry=bundle.lessons[id][lang][i];
 if(row.tex!==entry.tex)throw Error('Stale asset '+id);
 const asset=bundle.assets[entry.full];
 const expected=ts.reduce((n,t)=>n+(t.sub?2:1),0);
 if(asset.hints.length!==expected)throw Error('Missing base/subscript '+id+' '+row.tex);
 for(const h of asset.hints){if(!h.text||h.rect[2]<=0||h.rect[3]<=0)throw Error('Empty region');hits++;}
}
const result={formula_groups:Object.keys(formulas).length,language_rows:rows,symbols:used.size,hover_regions:hits,passed:true};
fs.writeFileSync(path.join(root,'qa/bulkhead-symbol-coverage.json'),JSON.stringify(result,null,2));console.log(result);
