///|
pub let item_vertex_shader : String =
  #| #version 300 es
  #| precision highp int;
  #| precision highp float;
  #| in vec3 position;
  #| in vec4 normal;
  #| in vec4 color;
  #| in vec3 textureCoord;
  #| uniform mat4 mvpMatrix;
  #| uniform mat4 normalMatrix;
  #| uniform vec3 diffuseLightDirection;
  #| uniform vec3 diffuseLightColor;
  #| uniform vec3 ambientLightColor;
  #| out vec4 vColor;
  #| out vec3 vTextureCoord;
  #| void main(void) {
  #|   gl_Position = mvpMatrix * vec4(position, 1.0);
  #|   vTextureCoord = textureCoord;
  #|   vec4 nor = normalMatrix * normal;
  #|   vec3 nor2 = normalize(nor.xyz);
  #|   float nDotL = max(dot(diffuseLightDirection, nor2), 0.0);
  #|   vec3 diffuse = diffuseLightColor * color.rgb * nDotL;
  #|   vec3 ambient = ambientLightColor * color.rgb;
  #|   vColor = vec4(diffuse + ambient, color.a);
  #| }

///|
pub let item_fragment_shader : String =
  #| #version 300 es
  #| precision highp int;
  #| precision highp float;
  #| uniform sampler2D blockTex;
  #| in vec4 vColor;
  #| in vec3 vTextureCoord;
  #| out vec4 fragmentColor;
  #| void main(void){
  #|   vec4 smpColor = texture(blockTex, vTextureCoord.xy);
  #|   if (smpColor.a == 0.0) discard;
  #|   fragmentColor = vColor * smpColor;
  #| }
