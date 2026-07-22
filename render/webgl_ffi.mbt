///|
/// Shader lifecycle.
pub extern "js" fn WebGLRenderingContext::create_shader(
  self : WebGLRenderingContext,
  type_ : Int,
) -> WebGLShader =
  #| (gl, type) => gl.createShader(type)

///|
pub extern "js" fn WebGLRenderingContext::shader_source(
  self : WebGLRenderingContext,
  shader : WebGLShader,
  source : String,
) -> Unit =
  #| (gl, shader, source) => gl.shaderSource(shader, source)

///|
pub extern "js" fn WebGLRenderingContext::compile_shader(
  self : WebGLRenderingContext,
  shader : WebGLShader,
) -> Unit =
  #| (gl, shader) => gl.compileShader(shader)

///|
pub extern "js" fn WebGLRenderingContext::get_shader_parameter(
  self : WebGLRenderingContext,
  shader : WebGLShader,
  pname : Int,
) -> Bool =
  #| (gl, shader, pname) => gl.getShaderParameter(shader, pname)

///|
pub extern "js" fn WebGLRenderingContext::get_shader_info_log(
  self : WebGLRenderingContext,
  shader : WebGLShader,
) -> String =
  #| (gl, shader) => gl.getShaderInfoLog(shader) ?? ""

///|
pub extern "js" fn WebGLRenderingContext::delete_shader(
  self : WebGLRenderingContext,
  shader : WebGLShader,
) -> Unit =
  #| (gl, shader) => gl.deleteShader(shader)

///|
pub extern "js" fn WebGLRenderingContext::create_program(
  self : WebGLRenderingContext,
) -> WebGLProgram =
  #| (gl) => gl.createProgram()

///|
pub extern "js" fn WebGLRenderingContext::attach_shader(
  self : WebGLRenderingContext,
  program : WebGLProgram,
  shader : WebGLShader,
) -> Unit =
  #| (gl, program, shader) => gl.attachShader(program, shader)

///|
pub extern "js" fn WebGLRenderingContext::link_program(
  self : WebGLRenderingContext,
  program : WebGLProgram,
) -> Unit =
  #| (gl, program) => gl.linkProgram(program)

///|
pub extern "js" fn WebGLRenderingContext::get_program_parameter(
  self : WebGLRenderingContext,
  program : WebGLProgram,
  pname : Int,
) -> Bool =
  #| (gl, program, pname) => gl.getProgramParameter(program, pname)

///|
pub extern "js" fn WebGLRenderingContext::get_program_info_log(
  self : WebGLRenderingContext,
  program : WebGLProgram,
) -> String =
  #| (gl, program) => gl.getProgramInfoLog(program) ?? ""

///|
pub extern "js" fn WebGLRenderingContext::delete_program(
  self : WebGLRenderingContext,
  program : WebGLProgram,
) -> Unit =
  #| (gl, program) => gl.deleteProgram(program)

///|
pub extern "js" fn WebGLRenderingContext::get_attrib_location(
  self : WebGLRenderingContext,
  program : WebGLProgram,
  name : String,
) -> Int =
  #| (gl, program, name) => gl.getAttribLocation(program, name)

///|
pub extern "js" fn WebGLRenderingContext::get_uniform_location(
  self : WebGLRenderingContext,
  program : WebGLProgram,
  name : String,
) -> WebGLUniformLocation =
  #| (gl, program, name) => gl.getUniformLocation(program, name)

///|
pub extern "js" fn WebGLRenderingContext::use_program(
  self : WebGLRenderingContext,
  program : WebGLProgram,
) -> Unit =
  #| (gl, program) => gl.useProgram(program)

///|
/// Buffer operations.
pub extern "js" fn WebGLRenderingContext::create_buffer(
  self : WebGLRenderingContext,
) -> WebGLBuffer =
  #| (gl) => gl.createBuffer()

///|
pub extern "js" fn WebGLRenderingContext::delete_buffer(
  self : WebGLRenderingContext,
  buffer : WebGLBuffer,
) -> Unit =
  #| (gl, buffer) => gl.deleteBuffer(buffer)

///|
pub extern "js" fn WebGLRenderingContext::bind_buffer(
  self : WebGLRenderingContext,
  target : Int,
  buffer : WebGLBuffer,
) -> Unit =
  #| (gl, target, buffer) => gl.bindBuffer(target, buffer)

///|
pub extern "js" fn WebGLRenderingContext::buffer_data_f32(
  self : WebGLRenderingContext,
  target : Int,
  data : Float32Array,
  usage : Int,
) -> Unit =
  #| (gl, target, data, usage) => gl.bufferData(target, data, usage)

///|
pub extern "js" fn WebGLRenderingContext::buffer_data_u16(
  self : WebGLRenderingContext,
  target : Int,
  data : Uint16Array,
  usage : Int,
) -> Unit =
  #| (gl, target, data, usage) => gl.bufferData(target, data, usage)

///|
pub extern "js" fn WebGLRenderingContext::buffer_data_u32(
  self : WebGLRenderingContext,
  target : Int,
  data : Uint32Array,
  usage : Int,
) -> Unit =
  #| (gl, target, data, usage) => gl.bufferData(target, data, usage)

///|
/// VAO operations.
pub extern "js" fn WebGLRenderingContext::create_vertex_array(
  self : WebGLRenderingContext,
) -> WebGLVertexArray =
  #| (gl) => gl.createVertexArray()

///|
pub extern "js" fn WebGLRenderingContext::bind_vertex_array(
  self : WebGLRenderingContext,
  vao : WebGLVertexArray,
) -> Unit =
  #| (gl, vao) => gl.bindVertexArray(vao)

///|
pub extern "js" fn WebGLRenderingContext::delete_vertex_array(
  self : WebGLRenderingContext,
  vao : WebGLVertexArray,
) -> Unit =
  #| (gl, vao) => gl.deleteVertexArray(vao)

///|
pub extern "js" fn WebGLRenderingContext::enable_vertex_attrib_array(
  self : WebGLRenderingContext,
  index : Int,
) -> Unit =
  #| (gl, index) => gl.enableVertexAttribArray(index)

///|
pub extern "js" fn WebGLRenderingContext::vertex_attrib_pointer(
  self : WebGLRenderingContext,
  index : Int,
  size : Int,
  type_ : Int,
  normalized : Bool,
  stride : Int,
  offset : Int,
) -> Unit =
  #| (gl, index, size, type, normalized, stride, offset) =>
  #|   gl.vertexAttribPointer(index, size, type, normalized, stride, offset)

///|
/// Texture operations.
pub extern "js" fn WebGLRenderingContext::create_texture(
  self : WebGLRenderingContext,
) -> WebGLTexture =
  #| (gl) => gl.createTexture()

///|
pub extern "js" fn WebGLRenderingContext::delete_texture(
  self : WebGLRenderingContext,
  tex : WebGLTexture,
) -> Unit =
  #| (gl, tex) => gl.deleteTexture(tex)

///|
pub extern "js" fn WebGLRenderingContext::bind_texture_2d(
  self : WebGLRenderingContext,
  tex : WebGLTexture,
) -> Unit =
  #| (gl, tex) => gl.bindTexture(gl.TEXTURE_2D, tex)

///|
pub extern "js" fn WebGLRenderingContext::unbind_texture_2d(
  self : WebGLRenderingContext,
) -> Unit =
  #| (gl) => gl.bindTexture(gl.TEXTURE_2D, null)

///|
pub extern "js" fn WebGLRenderingContext::unbind_pixel_unpack_buffer(
  self : WebGLRenderingContext,
) -> Unit =
  #| (gl) => gl.bindBuffer(gl.PIXEL_UNPACK_BUFFER, null)

///|
pub extern "js" fn WebGLRenderingContext::unbind_vertex_array(
  self : WebGLRenderingContext,
) -> Unit =
  #| (gl) => gl.bindVertexArray(null)

///|
pub extern "js" fn WebGLRenderingContext::tex_parameter_i(
  self : WebGLRenderingContext,
  target : Int,
  pname : Int,
  param : Int,
) -> Unit =
  #| (gl, target, pname, param) => gl.texParameteri(target, pname, param)

///|
pub extern "js" fn WebGLRenderingContext::tex_image_2d(
  self : WebGLRenderingContext,
  target : Int,
  level : Int,
  internal_format : Int,
  format : Int,
  type_ : Int,
  source : @ffi.JsValue,
) -> Unit =
  #| (gl, target, level, internalFormat, format, type, source) =>
  #|   gl.texImage2D(target, level, internalFormat, format, type, source)

///|
pub extern "js" fn WebGLRenderingContext::tex_image_2d_raw(
  self : WebGLRenderingContext,
  target : Int,
  level : Int,
  internal_format : Int,
  width : Int,
  height : Int,
  border : Int,
  format : Int,
  type_ : Int,
  pixels : @ffi.JsValue,
) -> Unit =
  #| (gl, target, level, internalFormat, width, height, border, format, type, pixels) =>
  #|   gl.texImage2D(target, level, internalFormat, width, height, border, format, type, pixels)

///|
pub extern "js" fn WebGLRenderingContext::generate_mipmap(
  self : WebGLRenderingContext,
  target : Int,
) -> Unit =
  #| (gl, target) => gl.generateMipmap(target)

///|
pub extern "js" fn WebGLRenderingContext::active_texture(
  self : WebGLRenderingContext,
  unit : Int,
) -> Unit =
  #| (gl, unit) => gl.activeTexture(unit)

///|
/// Uniform setters.
pub extern "js" fn WebGLRenderingContext::uniform_matrix4fv(
  self : WebGLRenderingContext,
  location : WebGLUniformLocation,
  transpose : Bool,
  value : Float32Array,
) -> Unit =
  #| (gl, location, transpose, value) =>
  #|   gl.uniformMatrix4fv(location, transpose, value)

///|
pub extern "js" fn WebGLRenderingContext::uniform_1i(
  self : WebGLRenderingContext,
  location : WebGLUniformLocation,
  value : Int,
) -> Unit =
  #| (gl, location, value) => gl.uniform1i(location, value)

///|
pub extern "js" fn WebGLRenderingContext::uniform_1f(
  self : WebGLRenderingContext,
  location : WebGLUniformLocation,
  value : Float,
) -> Unit =
  #| (gl, location, value) => gl.uniform1f(location, value)

///|
pub extern "js" fn WebGLRenderingContext::uniform_3f(
  self : WebGLRenderingContext,
  location : WebGLUniformLocation,
  x : Float,
  y : Float,
  z : Float,
) -> Unit =
  #| (gl, location, x, y, z) => gl.uniform3f(location, x, y, z)

///|
pub extern "js" fn WebGLRenderingContext::uniform_4f(
  self : WebGLRenderingContext,
  location : WebGLUniformLocation,
  x : Float,
  y : Float,
  z : Float,
  w : Float,
) -> Unit =
  #| (gl, location, x, y, z, w) => gl.uniform4f(location, x, y, z, w)

///|
/// State management.
pub extern "js" fn WebGLRenderingContext::enable(
  self : WebGLRenderingContext,
  cap : Int,
) -> Unit =
  #| (gl, cap) => gl.enable(cap)

///|
pub extern "js" fn WebGLRenderingContext::disable(
  self : WebGLRenderingContext,
  cap : Int,
) -> Unit =
  #| (gl, cap) => gl.disable(cap)

///|
pub extern "js" fn WebGLRenderingContext::blend_func(
  self : WebGLRenderingContext,
  sfactor : Int,
  dfactor : Int,
) -> Unit =
  #| (gl, sfactor, dfactor) => gl.blendFunc(sfactor, dfactor)

///|
pub extern "js" fn WebGLRenderingContext::depth_mask(
  self : WebGLRenderingContext,
  flag : Bool,
) -> Unit =
  #| (gl, flag) => gl.depthMask(flag)

///|
pub extern "js" fn WebGLRenderingContext::front_face(
  self : WebGLRenderingContext,
  mode : Int,
) -> Unit =
  #| (gl, mode) => gl.frontFace(mode)

///|
pub extern "js" fn WebGLRenderingContext::color_mask(
  self : WebGLRenderingContext,
  r : Bool,
  g : Bool,
  b : Bool,
  a : Bool,
) -> Unit =
  #| (gl, r, g, b, a) => gl.colorMask(r, g, b, a)

///|
/// Viewport.
pub extern "js" fn WebGLRenderingContext::viewport(
  self : WebGLRenderingContext,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> Unit =
  #| (gl, x, y, width, height) => gl.viewport(x, y, width, height)

///|
pub extern "js" fn WebGLRenderingContext::clear_color(
  self : WebGLRenderingContext,
  r : Float,
  g : Float,
  b : Float,
  a : Float,
) -> Unit =
  #| (gl, r, g, b, a) => gl.clearColor(r, g, b, a)

///|
pub extern "js" fn WebGLRenderingContext::clear(
  self : WebGLRenderingContext,
  mask : Int,
) -> Unit =
  #| (gl, mask) => gl.clear(mask)

///|
pub extern "js" fn WebGLRenderingContext::draw_arrays(
  self : WebGLRenderingContext,
  mode : Int,
  first : Int,
  count : Int,
) -> Unit =
  #| (gl, mode, first, count) => gl.drawArrays(mode, first, count)

///|
pub extern "js" fn WebGLRenderingContext::draw_elements(
  self : WebGLRenderingContext,
  mode : Int,
  count : Int,
  type_ : Int,
  offset : Int,
) -> Unit =
  #| (gl, mode, count, type, offset) => gl.drawElements(mode, count, type, offset)
