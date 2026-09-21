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
  #|   vNormal = transpose(inverse(mat3(uModel))) * aNormal;
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
  #| uniform float uLightScale;
  #| uniform bool uAlphaMask;
  #| uniform bool uAlphaBlend;
  #| uniform float uAlphaCutoff;
  #| uniform vec3 uFogColor;
  #| uniform float uFogNear;
  #| uniform float uFogFar;
  #| out vec4 outColor;
  #| void main() {
  #|   vec4 tex = uHasTexture ? texture(uTex, vUv) : vec4(1.0);
  #|   vec4 base = tex * uColor;
  #|   if (uAlphaMask && base.a < uAlphaCutoff) discard;
  #|   if (!uAlphaBlend) base.a = 1.0;
  #|   else if (base.a <= 0.0) discard;
  #|   vec3 lightDir = normalize(vec3(0.35, 0.75, 0.25));
  #|   vec3 normal = normalize(vNormal);
  #|   if (!gl_FrontFacing) normal = -normal;
  #|   float lit = max(dot(normal, lightDir), 0.0) * 0.6 + 0.4;
  #|   float fog = smoothstep(uFogNear, uFogFar, vFogDist);
  #|   outColor = vec4(mix(base.rgb * lit * uLightScale, uFogColor, fog), base.a);
  #| }
