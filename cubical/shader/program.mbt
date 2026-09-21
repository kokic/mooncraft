///|
/// Driver errors shared by all WebGL programs.
pub suberror ShaderError {
  CompileFailed(String)
  LinkFailed(String)
}

///|
/// Compile one stage, releasing it if the driver rejects the source.
pub fn compile_shader(
  gl : @webgl.WebGLRenderingContext,
  type_ : Int,
  source : String,
) -> @webgl.WebGLShader raise ShaderError {
  let shader = gl.create_shader(type_)
  gl.shader_source(shader, source)
  gl.compile_shader(shader)
  guard gl.get_shader_parameter(shader, @webgl.GL_COMPILE_STATUS) else {
    let log = gl.get_shader_info_log(shader)
    gl.delete_shader(shader)
    raise CompileFailed(log)
  }
  shader
}

///|
/// Compile and link a program. Temporary stages are released on success and
/// on failure; a program rejected by the linker is also released.
pub fn link_program(
  gl : @webgl.WebGLRenderingContext,
  vertex_source : String,
  fragment_source : String,
) -> @webgl.WebGLProgram raise ShaderError {
  let vertex = compile_shader(gl, @webgl.GL_VERTEX_SHADER, vertex_source)
  let fragment = {
    errdefer gl.delete_shader(vertex)
    compile_shader(gl, @webgl.GL_FRAGMENT_SHADER, fragment_source)
  }
  let program = gl.create_program()
  gl.attach_shader(program, vertex)
  gl.attach_shader(program, fragment)
  gl.link_program(program)
  gl.delete_shader(vertex)
  gl.delete_shader(fragment)
  guard gl.get_program_parameter(program, @webgl.GL_LINK_STATUS) else {
    let log = gl.get_program_info_log(program)
    gl.delete_program(program)
    raise LinkFailed(log)
  }
  program
}

///|
/// Browser entry point: return a WebGLProgram directly and throw on failure.
/// Program names select the canonical shader sources in this package.
#export_name("createProgram")
pub fn create_builtin_program(
  gl : @webgl.WebGLRenderingContext,
  name : String,
) -> @webgl.WebGLProgram {
  let (vertex, fragment) = match name {
    "world" => (world_vertex_shader, world_fragment_shader)
    "water" => (world_vertex_shader, water_fragment_shader)
    "leaf" => (leaf_vertex_shader, leaf_fragment_shader)
    "outline" => (outline_vertex_shader, outline_fragment_shader)
    "item" => (item_vertex_shader, item_fragment_shader)
    "gltf" => (GLTF_VS_SOURCE, GLTF_FS_SOURCE)
    _ => abort("unknown shader program: \{name}")
  }
  link_program(gl, vertex, fragment) catch {
    CompileFailed(log) => throw_program_error("shader compile: \{log}")
    LinkFailed(log) => throw_program_error("program link: \{log}")
  }
}

///|
extern "js" fn throw_program_error(message : String) -> @webgl.WebGLProgram =
  #| (message) => { throw new Error(message); }
