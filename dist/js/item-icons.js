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

function getMat4Api() {
  return {
    mul: window.mcMat4Mul,
    ortho: window.mcMat4Ortho,
    lookAt: window.mcMat4LookAt,
  };
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

    const leafVertexSource = window.mcOakLeavesVertexShader;
    const leafFragmentSource = window.mcOakLeavesFragmentShader;
    this.leafProgram = null;
    this.leafPosition = null;
    this.leafColor = null;
    this.leafUv = null;
    this.leafLayer = null;
    this.leafMvp = null;
    this.leafView = null;
    this.leafTex = null;
    this.leafTint = null;
    this.leafDebugSolid = null;
    this.leafFogColor = null;
    this.leafFogNear = null;
    this.leafFogFar = null;
    if (typeof leafVertexSource === "string" && typeof leafFragmentSource === "string") {
      this.leafProgram = createProgram(this.gl, leafVertexSource, leafFragmentSource);
      this.leafPosition = this.gl.getAttribLocation(this.leafProgram, "aPosition");
      this.leafColor = this.gl.getAttribLocation(this.leafProgram, "aColor");
      this.leafUv = this.gl.getAttribLocation(this.leafProgram, "aUv");
      this.leafLayer = this.gl.getAttribLocation(this.leafProgram, "aLayer");
      this.leafMvp = this.gl.getUniformLocation(this.leafProgram, "uMvp");
      this.leafView = this.gl.getUniformLocation(this.leafProgram, "uView");
      this.leafTex = this.gl.getUniformLocation(this.leafProgram, "uTex");
      this.leafTint = this.gl.getUniformLocation(this.leafProgram, "uLeafTint");
      this.leafDebugSolid = this.gl.getUniformLocation(this.leafProgram, "uDebugSolid");
      this.leafFogColor = this.gl.getUniformLocation(this.leafProgram, "uFogColor");
      this.leafFogNear = this.gl.getUniformLocation(this.leafProgram, "uFogNear");
      this.leafFogFar = this.gl.getUniformLocation(this.leafProgram, "uFogFar");
    }
    this.positionBuffer = this.gl.createBuffer();
    this.normalBuffer = this.gl.createBuffer();
    this.colorBuffer = this.gl.createBuffer();
    this.uvBuffer = this.gl.createBuffer();
    this.layerBuffer = this.gl.createBuffer();
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
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D_ARRAY, this.textureArray);

    const wsize = 0.425 + Math.SQRT2 / 4;
    const mat4 = getMat4Api();
    const proj = mat4.ortho(-wsize, wsize, -wsize, wsize, -1, 5);
    const view = mat4.lookAt([1, 12 / 16, 1], [0, 0, 0], [0, 1, 0]);
    const mvp = mat4.mul(proj, view);

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
    const uvs = Float32Array.from(mesh.uvs ?? []);
    const layers = Float32Array.from(mesh.layers ?? []);
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

    const useLeaf = item.material === "tinted_leaf";
    if (useLeaf) {
      if (!this.leafProgram) {
        throw new Error("leaf shader program unavailable for tinted items");
      }
      const tint = window.mcOakLeavesDefaultTint;
      if (!Array.isArray(tint) || tint.length < 3) {
        throw new Error("mcOakLeavesDefaultTint unavailable for tinted items");
      }
      gl.useProgram(this.leafProgram);
      gl.uniform1i(this.leafTex, 0);
      gl.uniformMatrix4fv(this.leafMvp, false, new Float32Array(mvp));
      gl.uniformMatrix4fv(this.leafView, false, new Float32Array(view));
      gl.uniform1f(this.leafDebugSolid, 0.0);
      gl.uniform3f(this.leafFogColor, 0.0, 0.0, 0.0);
      gl.uniform1f(this.leafFogNear, 1000.0);
      gl.uniform1f(this.leafFogFar, 2000.0);
      gl.uniform3f(this.leafTint, tint[0], tint[1], tint[2]);
    } else {
      gl.useProgram(this.program);
      gl.uniform1i(this.uTex, 0);
      gl.uniformMatrix4fv(this.uMvp, false, new Float32Array(mvp));
      gl.uniformMatrix4fv(this.uNormalMatrix, false, new Float32Array([
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
      ]));
      gl.uniform3f(this.uLightDir, 0.4, 1.0, 0.7);
      gl.uniform3f(this.uLightColor, 1.0, 1.0, 1.0);
      gl.uniform3f(this.uAmbientColor, 0.2, 0.2, 0.2);
    }

    gl.bindBuffer(gl.ARRAY_BUFFER, this.positionBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, positions, gl.DYNAMIC_DRAW);
    if (useLeaf) {
      gl.enableVertexAttribArray(this.leafPosition);
      gl.vertexAttribPointer(this.leafPosition, 3, gl.FLOAT, false, 0, 0);
    } else {
      gl.enableVertexAttribArray(this.aPosition);
      gl.vertexAttribPointer(this.aPosition, 3, gl.FLOAT, false, 0, 0);
    }

    if (!useLeaf) {
      gl.bindBuffer(gl.ARRAY_BUFFER, this.normalBuffer);
      gl.bufferData(gl.ARRAY_BUFFER, normals4, gl.DYNAMIC_DRAW);
      gl.enableVertexAttribArray(this.aNormal);
      gl.vertexAttribPointer(this.aNormal, 4, gl.FLOAT, false, 0, 0);
    }

    gl.bindBuffer(gl.ARRAY_BUFFER, this.colorBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, colors, gl.DYNAMIC_DRAW);
    if (useLeaf) {
      gl.enableVertexAttribArray(this.leafColor);
      gl.vertexAttribPointer(this.leafColor, 4, gl.FLOAT, false, 0, 0);
    } else {
      gl.enableVertexAttribArray(this.aColor);
      gl.vertexAttribPointer(this.aColor, 4, gl.FLOAT, false, 0, 0);
    }

    gl.bindBuffer(gl.ARRAY_BUFFER, this.uvBuffer);
    if (useLeaf) {
      gl.bufferData(gl.ARRAY_BUFFER, uvs, gl.DYNAMIC_DRAW);
      gl.enableVertexAttribArray(this.leafUv);
      gl.vertexAttribPointer(this.leafUv, 2, gl.FLOAT, false, 0, 0);
      gl.bindBuffer(gl.ARRAY_BUFFER, this.layerBuffer);
      gl.bufferData(gl.ARRAY_BUFFER, layers, gl.DYNAMIC_DRAW);
      gl.enableVertexAttribArray(this.leafLayer);
      gl.vertexAttribPointer(this.leafLayer, 1, gl.FLOAT, false, 0, 0);
    } else {
      gl.bufferData(gl.ARRAY_BUFFER, texcoords, gl.DYNAMIC_DRAW);
      gl.enableVertexAttribArray(this.aTex);
      gl.vertexAttribPointer(this.aTex, 3, gl.FLOAT, false, 0, 0);
    }

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
