"""Run in one visible Blender instance. Author an editable calm-sea asset."""
import bpy, math, json, traceback
from pathlib import Path
from mathutils import Vector, Quaternion
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/ocean'
OUT.mkdir(parents=True, exist_ok=True)

def build():
    try:
        # Launched with --factory-startup: only our new scene is modified.
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.object.delete(use_global=False)
        scene = bpy.context.scene
        scene.unit_settings.system = 'METRIC'
        bpy.ops.mesh.primitive_plane_add()
        sea = bpy.context.object
        sea.name = 'CalmOcean'
        ocean = sea.modifiers.new('Editable Ocean Spectrum', 'OCEAN')
        ocean.geometry_mode = 'GENERATE'
        ocean.resolution = 7
        ocean.viewport_resolution = 7
        ocean.spatial_size = 300
        ocean.wave_scale = .22
        ocean.wind_velocity = 7
        ocean.choppiness = .35
        ocean.time = 1.0
        sea.scale = (1.4, .8, 1)
        material = bpy.data.materials.new('Deep teal sea / small ripples')
        material.use_nodes = True
        nodes = material.node_tree.nodes
        links = material.node_tree.links
        bsdf = nodes.get('Principled BSDF')
        bsdf.inputs['Base Color'].default_value = (.015,.12,.16,1)
        bsdf.inputs['Roughness'].default_value = .23
        bsdf.inputs['Metallic'].default_value = .35
        noise = nodes.new('ShaderNodeTexNoise')
        noise.inputs['Scale'].default_value = 2.6
        noise.inputs['Detail'].default_value = 3
        coords = nodes.new('ShaderNodeTexCoord')
        bump = nodes.new('ShaderNodeBump')
        bump.inputs['Strength'].default_value = .22
        bump.inputs['Distance'].default_value = .10
        links.new(coords.outputs['Object'], noise.inputs['Vector'])
        links.new(noise.outputs['Fac'], bump.inputs['Height'])
        links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])
        sea.data.materials.append(material)
        # Periodic normal map: no visible seams when the runtime scrolls it.
        n = 512
        y, x = np.mgrid[0:n,0:n] * (2*math.pi/n)
        dx = np.zeros((n,n)); dy = np.zeros((n,n))
        rng = np.random.default_rng(2807)
        for _ in range(44):
            kx, ky = rng.integers(-28,29,size=2)
            length = max(1, math.hypot(kx,ky))
            amp = .045 / length
            phase = kx*x + ky*y + rng.uniform(0,2*math.pi)
            dx += amp*kx*np.cos(phase)
            dy += amp*ky*np.cos(phase)
        normal = np.stack((-dx,-dy,np.ones_like(dx)),axis=-1)
        normal /= np.linalg.norm(normal,axis=-1,keepdims=True)
        rgba = np.concatenate((normal*.5+.5,np.ones((n,n,1))),axis=-1)
        image = bpy.data.images.new('Ocean ripple normals',width=n,height=n)
        image.colorspace_settings.name = 'Non-Color'
        image.pixels.foreach_set(rgba.astype(np.float32).ravel())
        image.filepath_raw = str(OUT/'ripple_normal.png')
        image.file_format = 'PNG'
        image.save()
        # Export the evaluated ocean only; keep the modifier in the .blend.
        bpy.ops.object.select_all(action='DESELECT')
        sea.select_set(True); bpy.context.view_layer.objects.active = sea
        bpy.ops.export_scene.gltf(filepath=str(OUT/'calm_ocean.glb'),
            export_format='GLB',use_selection=True,export_apply=True)
        # Context ship is preview-only, never exported as part of the sea.
        bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/tanker_learning.glb'))
        for obj in bpy.context.selected_objects:
            if obj.parent is None: obj.location.z -= 10.4
        bpy.ops.object.light_add(type='AREA',location=(20,-30,90))
        bpy.context.object.data.energy = 110000
        bpy.context.object.data.shape = 'DISK'; bpy.context.object.data.size = 100
        scene.world.color = (.3,.4,.5)
        for area in bpy.context.screen.areas:
            if area.type == 'VIEW_3D':
                space=area.spaces.active; space.shading.type='MATERIAL'
                space.region_3d.view_distance=230
                space.region_3d.view_location=Vector((0,0,0))
                space.region_3d.view_rotation=Quaternion((.82,.46,-.17,-.29)).normalized()
                space.clip_end=2500
        bpy.ops.object.select_all(action='DESELECT')
        sea.select_set(True); bpy.context.view_layer.objects.active=sea
        bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'models/calm_ocean.blend'))
        (OUT/'build.json').write_text(json.dumps({'ok':True,'ocean_modifier':True,
            'dimensions_m':[420,240],'normal_map':[512,512],
            'source':'models/calm_ocean.blend'},indent=2))
    except Exception:
        (OUT/'build.json').write_text(json.dumps({'ok':False,'error':traceback.format_exc()}))
    return None

bpy.app.timers.register(build, first_interval=2)
