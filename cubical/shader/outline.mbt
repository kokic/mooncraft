///|
pub let outline_vertex_shader : String =
  #| #version 300 es
  #| in vec3 aPosition;
  #| uniform mat4 uMvp;
  #| uniform vec3 uOffset;
  #| uniform vec3 uViewOffset;
  #| void main() {
  #|   gl_Position = uMvp * vec4(aPosition + uOffset + uViewOffset, 1.0);
  #| }

///|
pub let outline_fragment_shader : String =
  #| #version 300 es
  #| precision mediump float;
  #| uniform vec4 uColor;
  #| out vec4 outColor;
  #| void main() {
  #|   outColor = uColor;
  #| }
