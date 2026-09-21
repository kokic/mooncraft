///|
/// Leaves and world geometry share the same vertex attributes and transforms.
pub let leaf_vertex_shader : String = world_vertex_shader

///|
/// Fragment shader for leaf tinting.
/// If biome tint is unavailable, use uLeafTint as a fallback.
pub let leaf_fragment_shader : String =
  #| #version 300 es
  #| precision highp float;
  #| in vec2 vUv;
  #| in vec2 vWorldXZ;
  #| in float vFogDistance;
  #| in vec4 vColor;
  #| uniform sampler2D uTex;
  #| uniform vec3 uLeafTint;
  #| uniform sampler2D uLeafTintTex;
  #| uniform vec2 uTintOrigin;
  #| uniform vec2 uTintInvSize;
  #| uniform float uTintStep;
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
  #|   vec4 color = texture(uTex, vUv);
  #|   if (color.a * vColor.a <= 0.3) {
  #|     discard;
  #|   }
  #|   float fogAmount = smoothstep(uFogNear, uFogFar, vFogDistance);
  #|   vec3 leafTint = uLeafTint;
  #|   if (uTintStep > 0.0) {
  #|     vec2 uv = ((vWorldXZ - uTintOrigin) / uTintStep + 0.5) * uTintInvSize;
  #|     leafTint = texture(uLeafTintTex, clamp(uv, vec2(0.0), vec2(1.0))).rgb;
  #|   }
  #|   vec3 tinted = vColor.rgb * color.rgb * leafTint;
  #|   vec3 mixed = mix(tinted, uFogColor, fogAmount);
  #|   outColor = vec4(mixed, color.a * vColor.a);
  #| }
