///|
pub let water_fragment_shader : String =
  #| #version 300 es
  #| precision highp float;
  #| in vec2 vUv;
  #| in float vFogDistance;
  #| in vec4 vColor;
  #| in vec2 vWorldXZ;
  #| uniform sampler2D uTex;
  #| uniform sampler2D uWaterTintTex;
  #| uniform vec3 uFogColor;
  #| uniform float uFogNear;
  #| uniform float uFogFar;
  #| uniform vec2 uWaterTintOrigin;
  #| uniform vec2 uWaterTintInvSize;
  #| uniform float uWaterTintStep;
  #| uniform float uUnderwater;
  #| out vec4 outColor;
  #| void main() {
  #|   vec4 color = texture(uTex, vUv);
  #|   if (color.a <= 0.01) {
  #|     discard;
  #|   }
  #|   vec3 waterTint = vec3(0.25, 0.46, 0.90);
  #|   if (uWaterTintStep > 0.0) {
  #|     vec2 cell = floor((vWorldXZ - uWaterTintOrigin) / uWaterTintStep + 0.5);
  #|     vec2 uv = (cell + 0.5) * uWaterTintInvSize;
  #|     uv = clamp(uv, vec2(0.0), vec2(1.0));
  #|     waterTint = texture(uWaterTintTex, uv).rgb;
  #|   }
  #|   float fogAmount = smoothstep(uFogNear, uFogFar, vFogDistance);
  #|   vec3 lit = vColor.rgb * color.rgb * waterTint;
  #|   vec3 mixed = mix(lit, uFogColor, fogAmount);
  #|   float alpha = clamp(color.a * vColor.a * mix(1.0, 1.35, uUnderwater), 0.0, 0.82);
  #|   outColor = vec4(mixed, alpha);
  #| }
