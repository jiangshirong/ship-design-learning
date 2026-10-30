"""Teacher notation from 6a/3. Пример компоновки ОР.docx, spacing section.
Ordinary transition spacing uses the regional suffix п.р., consistently
with the teacher's frame-spacing suffix р.н. п.р. (user-confirmed notation).
"""
MAPPING = {
 'transition':'п.р.',
 'adopt':'0 ср.ч.', 'mid':'0 ср.ч.', 'engine':'0 ср.ч.',
 'peak':'0 окон.', 'fore':'0 ф', 'aft':'0 ахт.',
 'web,cargo':'р.н. ср.ч.', 'web,engine':'р.н. МО',
 'web,transition':'р.н. п.р.', 'web,fore':'р.н. окон.',
 'web,aft':'р.н. окон.', 'web':'р.н. окон.',
}
def apply(formulas):
 for languages in formulas.values():
  for rows in languages.values():
   for row in rows:
    for key in ['tex']:
     value=row[key]
     for english,russian in MAPPING.items():
      replacement='a_{\\text{'+russian+'}}'
      value=value.replace('a_{\\mathrm{'+english+'}}',replacement)
      value=value.replace('a_{{'+english+'}}',replacement)
     if value=='a_{\\text{0 ср.ч.}}=a_{\\text{0 ср.ч.}}':value='a_{\\text{0 ср.ч.}}'
     row[key]=value

# DOCX notation takes precedence for longitudinal calculation; PPT for double hull.
# Auxiliary quantities absent from the teacher's notation use English subscripts.
    replacements = {
     r'n_{\text{ф}}':r'n_{\text{шп. ф}}',
     r'n_{\text{ахт}}':r'n_{\text{шп. а}}',
     r'n_{\mathrm{web}}':r'n_{\text{р.шп. МО}}',
     r'L_{\text{гр}}':r'L_{\text{гр.ч.}}',
     r'L_{\text{НО}}':r'L_{\mathrm{pump}}',
     r'x_{\text{пр}}':r's_{\mathrm{transition}}',
     r'L_{\text{гр1}}':r'L_{\mathrm{hold},1}',
     r'L_{\text{гр2}}':r'L_{\mathrm{hold},2}',
     r'L_{\text{гр}3-6}':r'L_{\mathrm{hold},3-6}',
     r'B_{\text{гр}}':r'B_{\mathrm{cargo}}',
     r'b_{\text{ц}}':r'b_{\mathrm{central}}',
     r'l_{\text{доп}}':r'l_{\mathrm{allow}}',
     r'h_{\text{дд},\min}':r'h_{\mathrm{min}}',
    }
    replacements[r'P_{\text{к.об}}']=r'P_{\text{коб},3}'
    replacements[r'P_{\text{сэу}}']=r'P_{\text{сэу},3}'
    for old,new in replacements.items():row['tex']=row['tex'].replace(old,new)
    # The DOCX spells the engine-room suffix М.О. in the spacing definition.
    row['tex']=row['tex'].replace(r'a_{\text{р.н. МО}}',r'a_{\text{р.н. М.О.}}')
    row['tex']=row['tex'].replace(r'L_{\text{гр.ч.}}=L-(L_{\text{ф}}+L_{\text{ахт}}+L_{\text{МО}}+L_{\mathrm{pump}})',r'L_{\text{гр.ч.}}=L-L_{\text{ф}}-L_{\text{ахт}}-L_{\text{МО}}-L_{\mathrm{pump}}')
    row['linear']=row['tex'].replace('\\text','').replace('\\mathrm','').replace('\\cdot',' * ').replace('\\,',' ')
