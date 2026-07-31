///|
/// Vertex shader for leaf tinting (matches the world renderer attributes).
pub let leaf_vertex_shader : String =
  #| #version 300 es
  #| precision highp float;
  #| precision highp int;
  #| in vec3 aPosition;
  #| in vec4 aColor;
  #| in vec2 aUv;
  #| in float aLayer;
  #| uniform mat4 uMvp;
  #| uniform vec3 uCameraPosition;
  #| out vec4 vColor;
  #| out float vFogDistance;
  #| out vec2 vUv;
  #| out float vLayer;
  #| void main() {
  #|   vUv = aUv;
  #|   vLayer = aLayer;
  #|   vColor = aColor;
  #|   vec4 pos = vec4(aPosition, 1.0);
  #|   vFogDistance = distance(aPosition, uCameraPosition);
  #|   gl_Position = uMvp * pos;
  #| }

///|
/// Fragment shader for leaf tinting.
/// If biome tint is unavailable, use uLeafTint as a fallback.
pub let leaf_fragment_shader : String =
  #| #version 300 es
  #| precision highp float;
  #| precision highp sampler2DArray;
  #| in vec2 vUv;
  #| in float vLayer;
  #| in float vFogDistance;
  #| in vec4 vColor;
  #| uniform sampler2DArray uTex;
  #| uniform vec3 uLeafTint;
  #| uniform float uDebugSolid;
  #| uniform vec3 uFogColor;
  #| uniform float uFogNear;
  #| uniform float uFogFar;
  #| out vec4 outColor;
  #| void main() {
  #|   if (uDebugSolid > 0.5) {
  #|     outColor = vec4(1.0, 0.2, 0.2, 1.0);
  #|     return;
  #|   }
  #|   vec4 color = texture(uTex, vec3(vUv, vLayer));
  #|   if (color.a * vColor.a <= 0.3) {
  #|     discard;
  #|   }
  #|   float fogAmount = smoothstep(uFogNear, uFogFar, vFogDistance);
  #|   vec3 tinted = vColor.rgb * color.rgb * uLeafTint;
  #|   vec3 mixed = mix(tinted, uFogColor, fogAmount);
  #|   outColor = vec4(mixed, color.a * vColor.a);
  #| }
