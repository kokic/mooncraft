///|
/// Create the glTF entity renderer and its shared shader program.
///
/// Raises `GltfError` when the WebGL shader compilation or linking fails.
pub fn create_gltf_renderer(
  gl : @webgl.WebGLRenderingContext,
  configs : Array[GltfEntityConfig],
  sample_light? : (Double, Double, Double) -> Float,
) -> GltfRenderer raise GltfError {
  let renderer = GltfRenderer::{
    gl,
    sample_light,
    program: create_gltf_program(gl, GLTF_VS_SOURCE, GLTF_FS_SOURCE),
    white_texture: create_white_texture(gl),
    assets: @hashmap.HashMap([]),
    textures: @hashmap.HashMap([]),
    instances: [],
  }
  for config in configs {
    renderer.add_entity(config)
  }
  renderer
}

///|
pub fn update_gltf_renderer(
  renderer : GltfRenderer,
  delta_seconds : Double,
) -> Unit {
  renderer.instances.each(instance => instance.update(delta_seconds))
}

///|
/// Draw opaque entities now; optionally enqueue blended primitives into the
/// world's transparent pass, which orders water, blocks, and entities together.
pub fn render_gltf_renderer(
  renderer : GltfRenderer,
  view : @ffi.Float32Array,
  view_projection : @ffi.Float32Array,
  camera_position : Array[Double],
  fog_color : Array[Double],
  fog_near : Double,
  fog_far : Double,
  submit_blend? : (Double, () -> Unit) -> Unit,
) -> Unit {
  guard renderer.instances.length() > 0 else { () }
  let (solid_entries, blend) = renderer.collect_draw_entries(camera_position)
  renderer.draw_entries(
    solid_entries, false, view, view_projection, fog_color, fog_near, fog_far,
  )
  if submit_blend is Some(submit) {
    for entry in blend {
      submit(entry.distance_squared.to_double(), () => {
        renderer.draw_entries(
          [entry],
          true,
          view,
          view_projection,
          fog_color,
          fog_near,
          fog_far,
        )
      })
    }
  } else {
    renderer.draw_entries(
      blend, true, view, view_projection, fog_color, fog_near, fog_far,
    )
  }
}
