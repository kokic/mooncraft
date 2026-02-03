const ICON_BASE_SIZE = 32;
const ICON_DEFAULT_CANVAS_SIZE = 256;
const ICON_FLAT_SIZE = 20;
const ICON_RENDER_SIZE = 512;

function setImageSmoothingEnabled(ctx, value) {
  ctx.mozImageSmoothingEnabled = value;
  ctx.webkitImageSmoothingEnabled = value;
  ctx.msImageSmoothingEnabled = value;
  ctx.imageSmoothingEnabled = value;
  ctx.oImageSmoothingEnabled = value;
}

function resolveTextureLayer(textures, name) {
  if (!textures || !textures.textureIndex || !textures.images) {
    throw new Error("resolveTextureLayer: textures not ready");
  }
  const index = textures.textureIndex.get(name);
  if (!Number.isInteger(index) || index < 0 || index >= textures.images.length) {
    const sampleNames = Array.from(textures.textureIndex.keys()).slice(0, 12);
    console.error("[item-icons] texture not found", {
      name,
      hasName: textures.textureIndex.has(name),
      textureCount: textures.images.length,
      sampleNames,
    });
    throw new Error(`resolveTextureLayer: texture not found: ${name}`);
  }
  return index;
}

function mat4Multiply(a, b) {
  const out = new Array(16);
  const a00 = a[0], a01 = a[1], a02 = a[2], a03 = a[3];
  const a10 = a[4], a11 = a[5], a12 = a[6], a13 = a[7];
  const a20 = a[8], a21 = a[9], a22 = a[10], a23 = a[11];
  const a30 = a[12], a31 = a[13], a32 = a[14], a33 = a[15];
  let b0 = b[0], b1 = b[1], b2 = b[2], b3 = b[3];
  out[0] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30;
  out[1] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31;
  out[2] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32;
  out[3] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33;
  b0 = b[4]; b1 = b[5]; b2 = b[6]; b3 = b[7];
  out[4] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30;
  out[5] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31;
  out[6] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32;
  out[7] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33;
  b0 = b[8]; b1 = b[9]; b2 = b[10]; b3 = b[11];
  out[8] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30;
  out[9] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31;
  out[10] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32;
  out[11] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33;
  b0 = b[12]; b1 = b[13]; b2 = b[14]; b3 = b[15];
  out[12] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30;
  out[13] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31;
  out[14] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32;
  out[15] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33;
  return out;
}

function mat4Ortho(l, r, b, t, n, f) {
  const lr = 1 / (l - r);
  const bt = 1 / (b - t);
  const nf = 1 / (n - f);
  return [
    -2 * lr, 0, 0, 0,
    0, -2 * bt, 0, 0,
    0, 0, 2 * nf, 0,
    (l + r) * lr, (t + b) * bt, (f + n) * nf, 1,
  ];
}

function vec3Normalize(v) {
  const len = Math.hypot(v[0], v[1], v[2]);
  if (len === 0) return [0, 0, 0];
  return [v[0] / len, v[1] / len, v[2] / len];
}

function vec3Cross(a, b) {
  return [
    a[1] * b[2] - a[2] * b[1],
    a[2] * b[0] - a[0] * b[2],
    a[0] * b[1] - a[1] * b[0],
  ];
}

function vec3Dot(a, b) {
  return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

function vec3Subtract(a, b) {
  return [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
}

function mat4LookAt(eye, center, up) {
  const zAxis = vec3Normalize(vec3Subtract(eye, center));
  const xAxis = vec3Normalize(vec3Cross(up, zAxis));
  const yAxis = vec3Cross(zAxis, xAxis);
  return [
    xAxis[0], yAxis[0], zAxis[0], 0,
    xAxis[1], yAxis[1], zAxis[1], 0,
    xAxis[2], yAxis[2], zAxis[2], 0,
    -vec3Dot(xAxis, eye), -vec3Dot(yAxis, eye), -vec3Dot(zAxis, eye), 1,
  ];
}

function createShader(gl, type, source) {
  const shader = gl.createShader(type);
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    const info = gl.getShaderInfoLog(shader);
    gl.deleteShader(shader);
    throw new Error(info || "shader compile failed");
  }
  return shader;
}

function createProgram(gl, vertexSource, fragmentSource) {
  const vertexShader = createShader(gl, gl.VERTEX_SHADER, vertexSource);
  const fragmentShader = createShader(gl, gl.FRAGMENT_SHADER, fragmentSource);
  const program = gl.createProgram();
  gl.attachShader(program, vertexShader);
  gl.attachShader(program, fragmentShader);
  gl.linkProgram(program);
  gl.deleteShader(vertexShader);
  gl.deleteShader(fragmentShader);
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    const info = gl.getProgramInfoLog(program);
    gl.deleteProgram(program);
    throw new Error(info || "program link failed");
  }
  return program;
}

function createTextureArray(gl, textures) {
  const tex = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D_ARRAY, tex);
  gl.texParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

  gl.texImage3D(
    gl.TEXTURE_2D_ARRAY,
    0,
    gl.RGBA,
    textures.singleWidth,
    textures.singleHeight,
    textures.layerCount,
    0,
    gl.RGBA,
    gl.UNSIGNED_BYTE,
    null,
  );

  textures.images.forEach((img, layer) => {
    gl.texSubImage3D(
      gl.TEXTURE_2D_ARRAY,
      0,
      0,
      0,
      layer,
      textures.singleWidth,
      textures.singleHeight,
      1,
      gl.RGBA,
      gl.UNSIGNED_BYTE,
      img,
    );
  });

  gl.bindTexture(gl.TEXTURE_2D_ARRAY, null);
  return tex;
}

class ItemIconRenderer {
  constructor() {
    this.canvas = document.createElement("canvas");
    this.gl = this.canvas.getContext("webgl2", { preserveDrawingBuffer: true });
    if (!this.gl) {
      throw new Error("webgl2 not supported");
    }
    const vertexSource = `#version 300 es
      precision highp int;
      precision highp float;
      in vec3 position;
      in vec4 normal;
      in vec4 color;
      in vec3 textureCoord;
      uniform mat4 mvpMatrix;
      uniform mat4 normalMatrix;
      uniform vec3 diffuseLightDirection;
      uniform vec3 diffuseLightColor;
      uniform vec3 ambientLightColor;
      out vec4 vColor;
      out vec3 vTextureCoord;
      void main(void) {
        gl_Position = mvpMatrix * vec4(position, 1.0);
        vTextureCoord = textureCoord;
        vec4 nor = normalMatrix * normal;
        vec3 nor2 = normalize(nor.xyz);
        float nDotL = max(dot(diffuseLightDirection, nor2), 0.0);
        vec3 diffuse = diffuseLightColor * color.rgb * nDotL;
        vec3 ambient = ambientLightColor * color.rgb;
        vColor = vec4(diffuse + ambient, color.a);
      }`;
    const fragmentSource = `#version 300 es
      precision highp int;
      precision highp float;
      precision highp sampler2DArray;
      uniform sampler2DArray blockTex;
      in vec4 vColor;
      in vec3 vTextureCoord;
      out vec4 fragmentColor;
      void main(void){
        vec4 smpColor = texture(blockTex, vTextureCoord);
        if (smpColor.a == 0.0) discard;
        fragmentColor = vColor * smpColor;
      }`;
    this.program = createProgram(this.gl, vertexSource, fragmentSource);
    this.aPosition = this.gl.getAttribLocation(this.program, "position");
    this.aNormal = this.gl.getAttribLocation(this.program, "normal");
    this.aColor = this.gl.getAttribLocation(this.program, "color");
    this.aTex = this.gl.getAttribLocation(this.program, "textureCoord");
    this.uMvp = this.gl.getUniformLocation(this.program, "mvpMatrix");
    this.uNormalMatrix = this.gl.getUniformLocation(this.program, "normalMatrix");
    this.uLightDir = this.gl.getUniformLocation(this.program, "diffuseLightDirection");
    this.uLightColor = this.gl.getUniformLocation(this.program, "diffuseLightColor");
    this.uAmbientColor = this.gl.getUniformLocation(this.program, "ambientLightColor");
    this.uTex = this.gl.getUniformLocation(this.program, "blockTex");
    this.positionBuffer = this.gl.createBuffer();
    this.normalBuffer = this.gl.createBuffer();
    this.colorBuffer = this.gl.createBuffer();
    this.uvBuffer = this.gl.createBuffer();
    this.textureArray = null;
    this.texturesRef = null;
  }

  ensureTextureArray(textures) {
    if (this.texturesRef === textures && this.textureArray) return;
    this.texturesRef = textures;
    if (this.textureArray) {
      this.gl.deleteTexture(this.textureArray);
    }
    this.textureArray = createTextureArray(this.gl, textures);
  }

  resize(width, height) {
    if (this.canvas.width === width && this.canvas.height === height) return;
    this.canvas.width = width;
    this.canvas.height = height;
    this.gl.viewport(0, 0, width, height);
  }

  renderItem(textures, item, width, height) {
    this.ensureTextureArray(textures);
    this.resize(width, height);
    const gl = this.gl;
    gl.clearColor(0, 0, 0, 0);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.enable(gl.DEPTH_TEST);
    gl.useProgram(this.program);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D_ARRAY, this.textureArray);
    gl.uniform1i(this.uTex, 0);

    const wsize = 0.425 + Math.SQRT2 / 4;
    const proj = mat4Ortho(-wsize, wsize, -wsize, wsize, -1, 5);
    const view = mat4LookAt([1, 12 / 16, 1], [0, 0, 0], [0, 1, 0]);
    const model = [
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      -0.5, -0.5, -0.5, 1,
    ];
    const mvp = mat4Multiply(proj, mat4Multiply(view, model));
    gl.uniformMatrix4fv(this.uMvp, false, new Float32Array(mvp));
    gl.uniformMatrix4fv(this.uNormalMatrix, false, new Float32Array(model));
    gl.uniform3f(this.uLightDir, 0.4, 1.0, 0.7);
    gl.uniform3f(this.uLightColor, 1.0, 1.0, 1.0);
    gl.uniform3f(this.uAmbientColor, 0.2, 0.2, 0.2);

    const longId = window.mcGetLongIdByName?.(item.name);
    if (!Number.isFinite(longId)) {
      throw new Error(`mcGetLongIdByName failed for ${item.name}`);
    }
    const registry = window.mcBlocks;
    if (!registry) {
      throw new Error("mcBlocks registry missing");
    }
    const mesh = window.mcBuildUiItemMesh?.(registry, longId);
    if (!mesh) {
      throw new Error("mcBuildUiItemMesh returned null");
    }
    const positions = Float32Array.from(mesh.positions ?? []);
    const colors = Float32Array.from(mesh.colors ?? []);
    const normals = Array.from(mesh.normals ?? []);
    const uvs = Array.from(mesh.uvs ?? []);
    const layers = Array.from(mesh.layers ?? []);
    const count = Number(mesh.count) || 0;
    const normals4 = new Float32Array((normals.length / 3) * 4);
    for (let i = 0, j = 0; i < normals.length; i += 3, j += 4) {
      normals4[j] = normals[i];
      normals4[j + 1] = normals[i + 1];
      normals4[j + 2] = normals[i + 2];
      normals4[j + 3] = 0;
    }
    const texcoords = new Float32Array(layers.length * 3);
    for (let i = 0; i < layers.length; i += 1) {
      texcoords[i * 3] = uvs[i * 2];
      texcoords[i * 3 + 1] = uvs[i * 2 + 1];
      texcoords[i * 3 + 2] = layers[i];
    }

    gl.bindBuffer(gl.ARRAY_BUFFER, this.positionBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, positions, gl.DYNAMIC_DRAW);
    gl.enableVertexAttribArray(this.aPosition);
    gl.vertexAttribPointer(this.aPosition, 3, gl.FLOAT, false, 0, 0);

    gl.bindBuffer(gl.ARRAY_BUFFER, this.normalBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, normals4, gl.DYNAMIC_DRAW);
    gl.enableVertexAttribArray(this.aNormal);
    gl.vertexAttribPointer(this.aNormal, 4, gl.FLOAT, false, 0, 0);

    gl.bindBuffer(gl.ARRAY_BUFFER, this.colorBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, colors, gl.DYNAMIC_DRAW);
    gl.enableVertexAttribArray(this.aColor);
    gl.vertexAttribPointer(this.aColor, 4, gl.FLOAT, false, 0, 0);

    gl.bindBuffer(gl.ARRAY_BUFFER, this.uvBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, texcoords, gl.DYNAMIC_DRAW);
    gl.enableVertexAttribArray(this.aTex);
    gl.vertexAttribPointer(this.aTex, 3, gl.FLOAT, false, 0, 0);

    gl.drawArrays(gl.TRIANGLES, 0, count);
  }
}

let sharedRenderer = null;
function getRenderer() {
  if (!sharedRenderer) sharedRenderer = new ItemIconRenderer();
  return sharedRenderer;
}

function drawItemIcon(ctx, textures, item, options = {}) {
  if (!item || !textures) {
    ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
    return;
  }
  const scale = typeof options.scale === "number" ? options.scale : 0.75;
  const offsetY = typeof options.offsetY === "number" ? options.offsetY : 0;
  const size = Math.min(ctx.canvas.width, ctx.canvas.height) * scale;
  const x = (ctx.canvas.width - size) / 2;
  const y = (ctx.canvas.height - size) / 2 + offsetY * size;
  const renderKind = item.kind === "flat" || item.shape === "torch" ? "flat" : item.kind;
  if (renderKind === "flat") {
    const layer = resolveTextureLayer(textures, item.texture?.name);
    const img = textures.images[layer];
    setImageSmoothingEnabled(ctx, false);
    ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
    ctx.drawImage(img, x, y, size, size);
    return;
  }
  const renderer = getRenderer();
  renderer.renderItem(textures, item, ICON_RENDER_SIZE, ICON_RENDER_SIZE);
  setImageSmoothingEnabled(ctx, false);
  ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
  ctx.drawImage(renderer.canvas, x, y, size, size);
}

export {
  ICON_BASE_SIZE,
  ICON_DEFAULT_CANVAS_SIZE,
  ICON_FLAT_SIZE,
  drawItemIcon,
  setImageSmoothingEnabled,
};
