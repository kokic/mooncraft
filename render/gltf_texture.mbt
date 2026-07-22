///|
pub extern "js" fn create_white_texture(gl : WebGLRenderingContext) -> WebGLTexture =
  #| (gl) => {
  #|   const tex = gl.createTexture();
  #|   gl.bindTexture(gl.TEXTURE_2D, tex);
  #|   gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  #|   gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  #|   gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  #|   gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  #|   gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array([255, 255, 255, 255]));
  #|   gl.bindTexture(gl.TEXTURE_2D, null);
  #|   return tex;
  #| }

///|
pub fn create_texture_from_image(
  gl : WebGLRenderingContext,
  image : @ffi.JsValue,
  min_filter : Int,
  mag_filter : Int,
  wrap_s : Int,
  wrap_t : Int,
) -> WebGLTexture {
  let tex = gl.create_texture()
  gl.bind_texture_2d(tex)
  gl.tex_parameter_i(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, min_filter)
  gl.tex_parameter_i(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, mag_filter)
  gl.tex_parameter_i(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrap_s)
  gl.tex_parameter_i(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrap_t)
  gl.tex_image_2d(GL_TEXTURE_2D, 0, GL_RGBA, GL_RGBA, GL_UNSIGNED_BYTE, image)
  if is_mip_filter(min_filter) {
    gl.generate_mipmap(GL_TEXTURE_2D)
  }
  gl.unbind_texture_2d()
  tex
}

///|
fn is_mip_filter(filter : Int) -> Bool {
  filter == 9984 || filter == 9985 || filter == 9986 || filter == 9987
}

///|
pub fn delete_gltf_texture(gl : WebGLRenderingContext, tex : WebGLTexture) -> Unit {
  gl.delete_texture(tex)
}
