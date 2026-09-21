///|
/// Fullscreen sky pass. The vertex stage emits a screen-covering triangle at
/// the far plane; the fragment stage rebuilds the view ray from the camera
/// basis and shades zenith, horizon, and the void below the horizon.
pub let sky_vertex_shader : String =
  #| #version 300 es
  #| precision highp float;
  #| in vec2 aPosition;
  #| out vec2 vNdc;
  #| void main() {
  #|   vNdc = aPosition;
  #|   gl_Position = vec4(aPosition, 1.0, 1.0);
  #| }

///|
pub let sky_fragment_shader : String =
  #| #version 300 es
  #| precision highp float;
  #| in vec2 vNdc;
  #| uniform vec3 uSkyCameraRight;
  #| uniform vec3 uSkyCameraUp;
  #| uniform vec3 uSkyCameraForward;
  #| uniform float uSkyTanHalfFov;
  #| uniform float uSkyAspect;
  #| uniform vec3 uSkyZenith;
  #| uniform vec3 uSkyHorizon;
  #| uniform vec3 uSkyVoid;
  #| out vec4 outColor;
  #| void main() {
  #|   vec3 ray = normalize(
  #|     uSkyCameraForward +
  #|     uSkyCameraRight * (vNdc.x * uSkyTanHalfFov * uSkyAspect) +
  #|     uSkyCameraUp * (vNdc.y * uSkyTanHalfFov)
  #|   );
  #|   float up = ray.y;
  #|   vec3 color = up >= 0.0
  #|     ? mix(uSkyHorizon, uSkyZenith, smoothstep(0.0, 1.0, up))
  #|     : mix(uSkyHorizon, uSkyVoid, smoothstep(0.0, 0.35, -up));
  #|   outColor = vec4(color, 1.0);
  #| }
