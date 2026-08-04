///|
/// Publish pure camera, matrix, quaternion, mesh, and GLTF rendering APIs.
pub fn register_render_api() -> Unit {
  @ffi.cast_global_set("mcCameraFromYawPitch", @camera.camera_from_yaw_pitch)
  // @ffi.cast_global_set("mcMat4Create", @camera.mat4_create)
  // @ffi.cast_global_set("mcMat4Copy", @camera.mat4_copy)
  @ffi.cast_global_set("mcUpVector", @camera.up_vector)
  // @ffi.cast_global_set("mcTransformPoint", @camera.transform_point)
  // @ffi.cast_global_set("mcQuatNormalize", @camera.quat_normalize)
  // @ffi.cast_global_set("mcQuatMul", @camera.quat_mul)
  // @ffi.cast_global_set("mcQuatApplyYawOffset", @camera.quat_apply_yaw_offset)
  // @ffi.cast_global_set("mcQuatFromYawPitch", @camera.quat_from_yaw_pitch)
  // @ffi.cast_global_set("mcQuatSlerp", @camera.quat_slerp)

  @ffi.cast_global_set("mcBlocks", @block.render_registry)

  @ffi.cast_global_set(
    "mcGetRenderBlockByInternalId", @block.get_render_block_by_internal_id,
  )
  @ffi.cast_global_set("mcBuildUiItemMesh", @ui.build_ui_item_mesh)
  @ffi.cast_global_set("mcParseGlb", @gltf.parse_glb)
  @ffi.cast_global_set("mcReadAccessorValues", @gltf.read_accessor_values)
  @ffi.cast_global_set("mcReadIndices", @gltf.read_indices)
  @ffi.cast_global_set("mcLoadBlockGltfModels", (on_done : (String) -> Unit) => {
    @gltf.load_block_gltf_models(@block.block_gltf_specs(), on_done)
  })
  @ffi.cast_global_set("mcCreateGltfProgram", @gltf.create_gltf_program)
  @ffi.cast_global_set("mcGltfVsSource", @gltf.GLTF_VS_SOURCE)
  @ffi.cast_global_set("mcGltfFsSource", @gltf.GLTF_FS_SOURCE)
  @ffi.cast_global_set("mcCreateWhiteTexture", @gltf.create_white_texture)
  @ffi.cast_global_set(
    "mcCreateTextureFromImage", @gltf.create_texture_from_image,
  )
  @ffi.cast_global_set("mcBuildGltfPrimitive", @gltf.build_gltf_primitive)
  @ffi.cast_global_set("mcDisposeGltfPrimitives", @gltf.dispose_gltf_primitives)
  @ffi.cast_global_set("mcCreateGltfRenderer", @gltf.create_gltf_renderer)
  @ffi.cast_global_set("mcUpdateGltfRenderer", @gltf.update_gltf_renderer)
  @ffi.cast_global_set("mcRenderGltfRenderer", @gltf.render_gltf_renderer)
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
