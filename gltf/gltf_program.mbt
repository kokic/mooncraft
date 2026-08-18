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
  let shader = gl.create_shader(type_)
  gl.shader_source(shader, source)
  gl.compile_shader(shader)
  if !gl.get_shader_parameter(shader, @webgl.GL_COMPILE_STATUS) {
    let log = gl.get_shader_info_log(shader)
    gl.delete_shader(shader)
    raise GltfError::ShaderCompileFailed(log)
  }
  shader
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
  let vs = compile_gltf_shader(gl, @webgl.GL_VERTEX_SHADER, vs_source)
  let fs = compile_gltf_shader(gl, @webgl.GL_FRAGMENT_SHADER, fs_source)
  let program = gl.create_program()
  gl.attach_shader(program, vs)
  gl.attach_shader(program, fs)
  gl.link_program(program)
  gl.delete_shader(vs)
  gl.delete_shader(fs)
  if !gl.get_program_parameter(program, @webgl.GL_LINK_STATUS) {
    let log = gl.get_program_info_log(program)
    gl.delete_program(program)
    raise GltfError::ProgramLinkFailed(log)
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
    u_alpha_mask: gl.get_uniform_location(program, "uAlphaMask"),
    u_alpha_cutoff: gl.get_uniform_location(program, "uAlphaCutoff"),
    u_fog_color: gl.get_uniform_location(program, "uFogColor"),
    u_fog_near: gl.get_uniform_location(program, "uFogNear"),
    u_fog_far: gl.get_uniform_location(program, "uFogFar"),
  }
}

///|
pub const GLTF_VS_SOURCE : String =
  #| #version 300 es
  #| precision highp float;
  #| in vec3 aPosition;
  #| in vec3 aNormal;
  #| in vec2 aUv;
  #| uniform mat4 uModel;
  #| uniform mat4 uView;
  #| uniform mat4 uViewProj;
  #| out vec3 vNormal;
  #| out vec2 vUv;
  #| out float vFogDist;
  #| void main() {
  #|   vec4 world = uModel * vec4(aPosition, 1.0);
  #|   vNormal = mat3(uModel) * aNormal;
  #|   vUv = aUv;
  #|   vFogDist = length((uView * world).xyz);
  #|   gl_Position = uViewProj * world;
  #| }

///|
pub const GLTF_FS_SOURCE : String =
  #| #version 300 es
  #| precision highp float;
  #| in vec3 vNormal;
  #| in vec2 vUv;
  #| in float vFogDist;
  #| uniform sampler2D uTex;
  #| uniform bool uHasTexture;
  #| uniform vec4 uColor;
  #| uniform bool uAlphaMask;
  #| uniform float uAlphaCutoff;
  #| uniform vec3 uFogColor;
  #| uniform float uFogNear;
  #| uniform float uFogFar;
  #| out vec4 outColor;
  #| void main() {
  #|   vec4 tex = uHasTexture ? texture(uTex, vUv) : vec4(1.0);
  #|   vec4 base = tex * uColor;
  #|   if (uAlphaMask && base.a < uAlphaCutoff) discard;
  #|   if (base.a <= 0.001) discard;
  #|   vec3 lightDir = normalize(vec3(0.35, 0.75, 0.25));
  #|   float lit = max(dot(normalize(vNormal), lightDir), 0.0) * 0.6 + 0.4;
  #|   float fog = smoothstep(uFogNear, uFogFar, vFogDist);
  #|   outColor = vec4(mix(base.rgb * lit, uFogColor, fog), base.a);
  #| }
