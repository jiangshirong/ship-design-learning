import bpy,json
from pathlib import Path
root=Path(r'D:\桌面文件夹\学习\大学课程\过考试\船舶设计原理\船舶原理学习')
# A new Blender process, inspect startup scene and source asset before authoring.
report={'startup':[(o.name,o.type) for o in bpy.context.scene.objects]}
bpy.ops.import_scene.gltf(filepath=str(root/'modules/review/assets/stability_fittings.glb'))
obs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.name!='Cube']
report['parts']=len(obs);report['examples']=[{'name':o.name,'location':list(o.location),'dimensions':list(o.dimensions)} for o in obs[:12]]
(root/'qa/freeboard-blender-inspect.json').write_text(json.dumps(report,indent=2))
