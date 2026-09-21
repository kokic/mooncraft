///|
/// Publish pure camera, matrix, quaternion, mesh, and GLTF rendering APIs.
pub fn register_render_api() -> Unit {
  @ffi.cast_global_set("mcCameraFromYawPitch", @camera.camera_from_yaw_pitch)
  @ffi.cast_global_set("mcUpVector", @camera.up_vector)

  @ffi.cast_global_set("mcBlocks", @block.render_registry)

  @ffi.cast_global_set(
    "mcGetRenderBlockByInternalId", @block.get_render_block_by_internal_id,
  )
  @ffi.cast_global_set("mcBuildUiItemMesh", @ui.build_ui_item_mesh)
  @ffi.cast_global_set("mcLoadBlockGltfModels", (on_done : (String) -> Unit) => {
    @gltf.load_block_gltf_models(@block.block_gltf_specs(), on_done)
  })
  // JS callers expect a renderer directly, not MoonBit's raising ABI.
  @ffi.cast_global_set("mcCreateGltfRenderer", (gl, configs, sample_light) => {
    try! @gltf.create_gltf_renderer(gl, configs, sample_light~)
  })
  @ffi.cast_global_set("mcUpdateGltfRenderer", @gltf.update_gltf_renderer)
  @ffi.cast_global_set("mcRenderGltfRenderer", (
    renderer,
    view,
    view_projection,
    camera_position,
    fog_color,
    fog_near,
    fog_far,
    submit_blend,
  ) => {
    @gltf.render_gltf_renderer(
      renderer,
      view,
      view_projection,
      camera_position,
      fog_color,
      fog_near,
      fog_far,
      submit_blend~,
    )
  })
  @ffi.cast_global_set("mcGltfSetAnimation", @gltf.gltf_set_animation)
  @ffi.cast_global_set("mcGltfSetTexture", @gltf.gltf_set_texture)
  @ffi.cast_global_set("mcGltfSetRotation", @gltf.gltf_set_rotation)
  @ffi.cast_global_set("mcGltfSetYaw", @gltf.gltf_set_yaw)
  @ffi.cast_global_set("mcGltfSetScale", @gltf.gltf_set_scale)
  @ffi.cast_global_set("mcGltfLookAtXz", @gltf.gltf_look_at_xz)
  @ffi.cast_global_set("mcGltfLookAtXyz", @gltf.gltf_look_at_xyz)
  @ffi.cast_global_set("mcGltfEntityIds", @gltf.gltf_entity_ids)
  @ffi.cast_global_set("mcGltfEntityCount", @gltf.gltf_entity_count)
}
