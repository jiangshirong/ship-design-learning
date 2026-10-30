const terms=require('../../content/english_notation_terms.json');
module.exports=function annotateEnglish(tex,markers){
 return tex.replace(/(\\[a-zA-Z]+|[A-Za-z])_\{\\(text|mathrm)\{([A-Za-z,]+)\}/g,(all,base,style,suffix)=>{
  const hint=terms[base+'|'+suffix];
  if(!hint)throw Error('Missing English variable meaning: '+base+'|'+suffix);
  const baseId='term'+Object.keys(markers).length;markers[baseId]=hint;
  const subId='term'+Object.keys(markers).length;markers[subId]=hint;
  return `\\cssId{${baseId}}{${base}}_{\\cssId{${subId}}{\\${style}{${suffix}}}`;
 });
};
