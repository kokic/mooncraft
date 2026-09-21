///|
/// Compile a WebGL shader.
///
/// Raises `GltfError::ShaderCompileFailed` with the driver log when the
/// compiler rejects the source.
pub fn compile_gltf_shader(
  gl : @webgl.WebGLRenderingContext,
  type_ : Int,
  source : String,
) -> @webgl.WebGLShader raise GltfError {
  @shader.compile_shader(gl, type_, source) catch {
    error => raise GltfError::from_shader(error)
  }
}

///|
/// Link a glTF vertex/fragment program.
///
/// Raises `GltfError::ShaderCompileFailed` or `GltfError::ProgramLinkFailed`
/// with the driver log when compilation or linking fails.
pub fn create_gltf_program(
  gl : @webgl.WebGLRenderingContext,
  vs_source : String,
  fs_source : String,
) -> GltfProgramInfo raise GltfError {
  let program = @shader.link_program(gl, vs_source, fs_source) catch {
    error => raise GltfError::from_shader(error)
  }
  {
    program,
    a_position: gl.get_attrib_location(program, "aPosition"),
    a_normal: gl.get_attrib_location(program, "aNormal"),
    a_uv: gl.get_attrib_location(program, "aUv"),
    u_model: gl.get_uniform_location(program, "uModel"),
    u_view: gl.get_uniform_location(program, "uView"),
    u_view_proj: gl.get_uniform_location(program, "uViewProj"),
    u_tex: gl.get_uniform_location(program, "uTex"),
    u_has_texture: gl.get_uniform_location(program, "uHasTexture"),
    u_color: gl.get_uniform_location(program, "uColor"),
    u_light_scale: gl.get_uniform_location(program, "uLightScale"),
    u_alpha_mask: gl.get_uniform_location(program, "uAlphaMask"),
    u_alpha_blend: gl.get_uniform_location(program, "uAlphaBlend"),
    u_alpha_cutoff: gl.get_uniform_location(program, "uAlphaCutoff"),
    u_fog_color: gl.get_uniform_location(program, "uFogColor"),
    u_fog_near: gl.get_uniform_location(program, "uFogNear"),
    u_fog_far: gl.get_uniform_location(program, "uFogFar"),
  }
}

///|
pub using @shader {GLTF_VS_SOURCE, GLTF_FS_SOURCE}
