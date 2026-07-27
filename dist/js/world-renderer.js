import {
  createPlayerController,
} from "./player-controller.js";
import { createHotbarUI } from "./hotbar-ui.js";
import { createInventoryUI } from "./inventory-ui.js";
import { createChatUI } from "./chat-ui.js";
import { unpackLongId } from "./block-registry.js";
const UPDATE_LABEL = window.mcUpdateLabel;
const CLIENT_BUILD_TIME = "2026-07-27T08:53:26+08:00";
const DEFAULT_MESH_SECTION_SIZE = 8;
const HOTBAR_SLOT_COUNT = 9;

function normalizeGameMode(mode) {
  return mode === "survival" || mode === "spectator" ? mode : "creative";
}

function getBlockShapeDesc(longId) {
  return window.mcGetBlockShapeDesc(longId);
}

function getTorchShapeBoxByState(state) {
  const value = window.mcTorchShapeBoxByState?.(state);
  if (!value || !Array.isArray(value.min) || !Array.isArray(value.max)) {
    return null;
  }
  return value;
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

function getBlockIdAtOrDefault(chunkDatas, size, wx, wy, wz, fallbackId) {
  const value = window.mcGetBlockId(chunkDatas, size, wx, wy, wz);
  const num = Number(value);
  return Number.isFinite(num) ? num : fallbackId;
}

function setBlockIdAt(chunkDatas, size, wx, wy, wz, id) {
  const value = window.mcSetBlockId(chunkDatas, size, wx, wy, wz, id);
  if (!Array.isArray(value)) {
    throw new Error("mcSetBlockId returned non-array");
  }
  return value;
}

function normalizeWaterTintSample(value) {
  if (!Array.isArray(value) || value.length < 4) return [1, 1, 1, 1];
  return value.map((v) => { const n = Number(v); return Number.isFinite(n) ? n : 1; });
}

function toColorByte(value) {
  const v = Number.isFinite(value) ? value : 1;
  const scaled = Math.round(Math.min(1, Math.max(0, v)) * 255);
  return scaled & 0xff;
}

function createOutlineProgram(gl) {
  const vertexSource = `#version 300 es
    in vec3 aPosition;
    uniform mat4 uMvp;
    uniform vec3 uOffset;
    uniform vec3 uViewOffset;
    void main() {
      gl_Position = uMvp * vec4(aPosition + uOffset + uViewOffset, 1.0);
    }
  `;
  const fragmentSource = `#version 300 es
    precision mediump float;
    uniform vec4 uColor;
    out vec4 outColor;
    void main() {
      outColor = uColor;
    }
  `;
  return createProgram(gl, vertexSource, fragmentSource);
}

function createOutlineBuffer(gl, bounds = { min: [0, 0, 0], max: [1, 1, 1] }, pad = {
  sx: 0,
  sy: 0,
  sz: 0,
  ex: 0,
  ey: 0,
  ez: 0,
}) {
  const sX = bounds.min[0] - pad.sx;
  const sY = bounds.min[1] - pad.sy;
  const sZ = bounds.min[2] - pad.sz;
  const eX = bounds.max[0] + pad.ex;
  const eY = bounds.max[1] + pad.ey;
  const eZ = bounds.max[2] + pad.ez;
  const lines = new Float32Array([
    sX, sY, sZ, eX, sY, sZ,
    eX, sY, sZ, eX, sY, eZ,
    eX, sY, eZ, sX, sY, eZ,
    sX, sY, eZ, sX, sY, sZ,

    sX, eY, sZ, eX, eY, sZ,
    eX, eY, sZ, eX, eY, eZ,
    eX, eY, eZ, sX, eY, eZ,
    sX, eY, eZ, sX, eY, sZ,

    sX, sY, sZ, sX, eY, sZ,
    eX, sY, sZ, eX, eY, sZ,
    eX, sY, eZ, eX, eY, eZ,
    sX, sY, eZ, sX, eY, eZ,
  ]);
  const buffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  gl.bufferData(gl.ARRAY_BUFFER, lines, gl.STATIC_DRAW);
  return { buffer, count: lines.length / 3 };
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

function normalizeChunkData(data, fallback = null) {
  if (!data) return fallback;
  if (Array.isArray(data)) return data;
  if (data instanceof Uint32Array || typeof data.length === "number") {
    return Array.from(data);
  }
  return fallback;
}

function createCanvas() {
  const canvas = document.createElement("canvas");
  canvas.tabIndex = 0;
  document.body.appendChild(canvas);
  canvas.style.width = "100vw";
  canvas.style.height = "100vh";
  return canvas;
}

function resizeCanvas(gl, canvas) {
  const dpr = window.devicePixelRatio || 1;
  const width = Math.floor(canvas.clientWidth * dpr);
  const height = Math.floor(canvas.clientHeight * dpr);
  if (canvas.width !== width || canvas.height !== height) {
    canvas.width = width;
    canvas.height = height;
  }
  gl.viewport(0, 0, canvas.width, canvas.height);
  return { width: canvas.width, height: canvas.height };
}

function renderTestChunk({
  blockRegistry,
  textures,
  chunkSize,
  persistSave,
}) {
  const {
    mcUpVector: UP_VECTOR,
    mcCameraFromYawPitchInto: cameraFromYawPitchInto,
    mcMat4Perspective: mat4Perspective,
    mcMat4LookAt: mat4LookAt,
    mcMat4Mul: mat4Mul,
  } = window;
  const cameraFromYawPitch = (out, px, py, pz, yaw, pitch) => {
    cameraFromYawPitchInto(
      out.position,
      out.direction,
      out.center,
      px,
      py,
      pz,
      yaw,
      pitch,
    );
    return out;
  };
  const canvas = createCanvas();
  const gl = canvas.getContext("webgl2", {
    alpha: false, 
    powerPreference: "high-performance", 
  });
  if (!gl) throw new Error("webgl2 not supported");

  const vertexSource = `#version 300 es
    precision highp float;
    precision highp int;
    in vec3 aPosition;
    in vec4 aColor;
    in vec2 aUv;
    in float aLayer;
    uniform mat4 uMvp;
    uniform vec3 uCameraPosition;
    out vec4 vColor;
    out float vFogDistance;
    out vec2 vUv;
    out float vLayer;
    out vec2 vWorldXZ;
    void main() {
      vUv = aUv;
      vLayer = aLayer;
      vColor = aColor;
      vWorldXZ = aPosition.xz;
      vec4 pos = vec4(aPosition, 1.0);
      vFogDistance = distance(aPosition, uCameraPosition);
      gl_Position = uMvp * pos;
    }
  `;

  const fragmentSource = `#version 300 es
    precision highp float;
    precision highp sampler2DArray;
    in vec2 vUv;
    in float vLayer;
    in float vFogDistance;
    in vec4 vColor;
    uniform sampler2DArray uTex;
    uniform float uDebugSolid;
    uniform vec3 uFogColor;
    uniform float uFogNear;
    uniform float uFogFar;
    out vec4 outColor;
    void main() {
      if (uDebugSolid > 0.5) {
        outColor = vec4(1.0, 0.2, 0.2, 1.0);
        return;
      }
      vec4 color = texture(uTex, vec3(vUv, vLayer));
      if (color.a * vColor.a <= 0.3) {
        discard;
      }
      float fogAmount = smoothstep(uFogNear, uFogFar, vFogDistance);
      vec3 mixed = mix(vColor.rgb * color.rgb, uFogColor, fogAmount);
      outColor = vec4(mixed, color.a * vColor.a);
    }
  `;

  const waterFragmentSource = `#version 300 es
    precision highp float;
    precision highp sampler2DArray;
    in vec2 vUv;
    in float vLayer;
    in float vFogDistance;
    in vec4 vColor;
    in vec2 vWorldXZ;
    uniform sampler2DArray uTex;
    uniform sampler2D uWaterTintTex;
    uniform vec3 uFogColor;
    uniform float uFogNear;
    uniform float uFogFar;
    uniform vec2 uWaterTintOrigin;
    uniform vec2 uWaterTintInvSize;
    uniform float uWaterTintStep;
    uniform float uUnderwater;
    out vec4 outColor;
    void main() {
      vec4 color = texture(uTex, vec3(vUv, vLayer));
      if (color.a <= 0.01) {
        discard;
      }
      vec3 waterTint = vec3(0.25, 0.46, 0.90);
      if (uWaterTintStep > 0.0) {
        vec2 cell = floor((vWorldXZ - uWaterTintOrigin) / uWaterTintStep + 0.5);
        vec2 uv = (cell + 0.5) * uWaterTintInvSize;
        uv = clamp(uv, vec2(0.0), vec2(1.0));
        waterTint = texture(uWaterTintTex, uv).rgb;
      }
      float fogAmount = smoothstep(uFogNear, uFogFar, vFogDistance);
      vec3 lit = vColor.rgb * color.rgb * waterTint;
      vec3 mixed = mix(lit, uFogColor, fogAmount);
      float alpha = clamp(color.a * vColor.a * mix(1.0, 1.35, uUnderwater), 0.0, 0.82);
      outColor = vec4(mixed, alpha);
    }
  `;

  const program = createProgram(gl, vertexSource, fragmentSource);
  const waterProgram = createProgram(gl, vertexSource, waterFragmentSource);
  const leafVertexSource = window.mcOakLeavesVertexShader;
  const leafFragmentSource = window.mcOakLeavesFragmentShader;
  if (typeof leafVertexSource !== "string" || typeof leafFragmentSource !== "string") {
    throw new Error("oak leaves shaders unavailable from MoonBit");
  }
  const leafProgram = createProgram(gl, leafVertexSource, leafFragmentSource);
  const outlineProgram = createOutlineProgram(gl);
  const outlineCube = createOutlineBuffer(gl);
  const outlineCache = new Map();
  const getOutlineBuffer = (bounds) => {
    const key = `${bounds.min.join(",")}|${bounds.max.join(",")}`;
    const cached = outlineCache.get(key);
    if (cached) return cached;
    const buffer = createOutlineBuffer(gl, bounds);
    outlineCache.set(key, buffer);
    return buffer;
  };
  if (typeof persistSave !== "function") {
    throw new Error("IndexedDB save callback is unavailable");
  }
  const size = chunkSize ?? 16;
  const chunkDatas = window.mcChunkRuntimeChunkMap;
  if (!(chunkDatas instanceof Map)) {
    throw new Error("MoonBit chunk runtime did not provide its chunk map");
  }
  const chunkMeshes = new Map();
  const rawAirLongId = Number(window.mcAirLongId ?? 0);
  const airLongId = Number.isFinite(rawAirLongId) ? rawAirLongId : 0;
  const meshSectionRaw = Number(window.mcChunkSectionSize ?? DEFAULT_MESH_SECTION_SIZE);
  const meshSectionSize = Number.isFinite(meshSectionRaw)
    ? Math.max(1, Math.floor(meshSectionRaw))
    : DEFAULT_MESH_SECTION_SIZE;
  const deleteMeshBuffers = (buffers) => {
    if (!buffers) return;
    if (buffers.vaoWorld) gl.deleteVertexArray(buffers.vaoWorld);
    if (buffers.vaoLeaf) gl.deleteVertexArray(buffers.vaoLeaf);
    if (buffers.vaoWater) gl.deleteVertexArray(buffers.vaoWater);
    if (buffers.positionBuffer) gl.deleteBuffer(buffers.positionBuffer);
    if (buffers.colorBuffer) gl.deleteBuffer(buffers.colorBuffer);
    if (buffers.uvBuffer) gl.deleteBuffer(buffers.uvBuffer);
    if (buffers.layerBuffer) gl.deleteBuffer(buffers.layerBuffer);
  };
  const deleteChunkMesh = (mesh) => {
    if (!mesh) return;
    if (mesh.sections instanceof Map) {
      for (const section of mesh.sections.values()) {
        deleteMeshBuffers(section.normal);
        deleteMeshBuffers(section.leaf);
        deleteMeshBuffers(section.water);
        deleteMeshBuffers(section.translucent);
      }
      mesh.sections.clear();
      return;
    }
    deleteMeshBuffers(mesh.normal);
    deleteMeshBuffers(mesh.leaf);
    deleteMeshBuffers(mesh.water);
    deleteMeshBuffers(mesh.translucent);
  };
  const toBuffers = (mesh) => {
    const positions = new Float32Array(mesh.positions);
    const uvs = new Float32Array(mesh.uvs);
    const layers = new Float32Array(mesh.layers);
    let colors = new Float32Array(mesh.colors ?? []);
    if (colors.length === 0 && mesh.count > 0) {
      colors = new Float32Array(mesh.count * 4);
      for (let i = 0; i < colors.length; i += 4) {
        colors[i] = 1;
        colors[i + 1] = 1;
        colors[i + 2] = 1;
        colors[i + 3] = 1;
      }
    }
    const positionBuffer = gl.createBuffer();
    const uvBuffer = gl.createBuffer();
    const layerBuffer = gl.createBuffer();
    const colorBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, positions, gl.STATIC_DRAW);
    gl.bindBuffer(gl.ARRAY_BUFFER, colorBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, colors, gl.DYNAMIC_DRAW);
    gl.bindBuffer(gl.ARRAY_BUFFER, uvBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, uvs, gl.STATIC_DRAW);
    gl.bindBuffer(gl.ARRAY_BUFFER, layerBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, layers, gl.STATIC_DRAW);
    return {
      count: mesh.count,
      vaoWorld: null,
      vaoLeaf: null,
      vaoWater: null,
      positionBuffer,
      colorBuffer,
      uvBuffer,
      layerBuffer,
    };
  };
  const getOrCreateChunkMesh = (key) => {
    const prev = chunkMeshes.get(key);
    if (prev && prev.sections instanceof Map) {
      return prev;
    }
    if (prev) {
      deleteChunkMesh(prev);
    }
    const mesh = { sections: new Map() };
    chunkMeshes.set(key, mesh);
    return mesh;
  };
  const applyMeshCommand = (command) => {
    const key = command?.chunk_key;
    const mesh = command?.mesh;
    if (typeof key !== "string" ||
      !mesh?.normal || !mesh?.leaf || !mesh?.water || !mesh?.translucent) {
      throw new Error("MoonBit emitted an invalid chunk mesh command");
    }
    const chunkMesh = getOrCreateChunkMesh(key);
    const id = `${command.x},${command.y},${command.z}`;
    const prevSection = chunkMesh.sections.get(id);
    if (prevSection) {
      deleteMeshBuffers(prevSection.normal);
      deleteMeshBuffers(prevSection.leaf);
      deleteMeshBuffers(prevSection.water);
      deleteMeshBuffers(prevSection.translucent);
    }
    chunkMesh.sections.set(id, {
      centerX: Number(command.center_x),
      centerY: Number(command.center_y),
      centerZ: Number(command.center_z),
      normal: toBuffers(mesh.normal),
      leaf: toBuffers(mesh.leaf),
      water: toBuffers(mesh.water),
      translucent: toBuffers(mesh.translucent),
    });
  };
  const applyRecolorCommand = (command) => {
    const chunkMesh = chunkMeshes.get(command?.chunk_key);
    const section = chunkMesh?.sections?.get(`${command?.x},${command?.y},${command?.z}`);
    const colors = command?.colors;
    if (!section || !colors) return false;
    const uploadColors = (part, colors) => {
      const expected = part.count * 4;
      const arr = Float32Array.from(colors ?? []);
      if (part.count > 0 && arr.length !== expected) {
        return false;
      }
      gl.bindBuffer(gl.ARRAY_BUFFER, part.colorBuffer);
      gl.bufferData(gl.ARRAY_BUFFER, arr, gl.DYNAMIC_DRAW);
      return true;
    };
    return uploadColors(section.normal, colors.normal) &&
      uploadColors(section.leaf, colors.leaf) &&
      uploadColors(section.water, colors.water) &&
      uploadColors(section.translucent, colors.translucent);
  };

  const textureArray = createTextureArray(gl, textures);
  const gltfEntityRenderer = window.mcCreateGltfRenderer(
    gl,
    Array.isArray(window.mcGltfEntities) ? window.mcGltfEntities : [],
  );
  window.mcGltfEntityApi = {
    setAnimation(entityId, clip) {
      return window.mcGltfSetAnimation(gltfEntityRenderer, entityId, clip);
    },
    setTexture(entityId, path) {
      return window.mcGltfSetTexture(gltfEntityRenderer, entityId, path);
    },
    setRotationQuat(entityId, x, y, z, w) {
      return window.mcGltfSetRotation(gltfEntityRenderer, entityId, x, y, z, w);
    },
    setYaw(entityId, yaw) {
      return window.mcGltfSetYaw(gltfEntityRenderer, entityId, yaw);
    },
    setScale(entityId, x, y, z) {
      return window.mcGltfSetScale(gltfEntityRenderer, entityId, x, y, z);
    },
    lookAtXz(entityId, x, z) {
      return window.mcGltfLookAtXz(gltfEntityRenderer, entityId, x, z);
    },
    lookAtXyz(entityId, x, y, z) {
      return window.mcGltfLookAtXyz(gltfEntityRenderer, entityId, x, y, z);
    },
    getEntityIds() {
      return window.mcGltfEntityIds(gltfEntityRenderer);
    },
    getInstanceCount() {
      return window.mcGltfEntityCount(gltfEntityRenderer);
    },
  };
  const rawWaterLayer = textures?.textureIndex?.get("water_still");
  const waterLayer = Number.isFinite(Number(rawWaterLayer))
    ? Number(rawWaterLayer)
    : -1;
  const getWaterTintAt = typeof window.mcGetWaterTint === "function"
    ? window.mcGetWaterTint
    : null;
  const rawWaterTintStep = Number(window.mcWaterTintGridStep ?? 4);
  const waterTintGridStep = Number.isFinite(rawWaterTintStep)
    ? Math.max(1, Math.floor(rawWaterTintStep))
    : 4;
  const hasWaterTintLookup = !!getWaterTintAt && waterLayer >= 0;
  const waterTintTexture = hasWaterTintLookup ? gl.createTexture() : null;
  const waterTintState = {
    centerCx: Number.NaN,
    centerCz: Number.NaN,
    renderDistance: -1,
    originX: 0,
    originZ: 0,
    width: 1,
    height: 1,
    step: waterTintGridStep,
    valid: false,
  };
  const rebuildWaterTintTexture = (centerCx, centerCz, renderDistance) => {
    if (!waterTintTexture || typeof getWaterTintAt !== "function") return;
    const marginChunks = 2;
    const minChunkX = centerCx - renderDistance - marginChunks;
    const maxChunkX = centerCx + renderDistance + marginChunks;
    const minChunkZ = centerCz - renderDistance - marginChunks;
    const maxChunkZ = centerCz + renderDistance + marginChunks;
    const originX = minChunkX * size;
    const originZ = minChunkZ * size;
    const maxX = (maxChunkX + 1) * size - 1;
    const maxZ = (maxChunkZ + 1) * size - 1;
    const width = Math.max(1, Math.floor((maxX - originX) / waterTintGridStep) + 1);
    const height = Math.max(1, Math.floor((maxZ - originZ) / waterTintGridStep) + 1);
    const pixels = new Uint8Array(width * height * 4);
    let ptr = 0;
    for (let z = 0; z < height; z += 1) {
      const wz = originZ + z * waterTintGridStep;
      for (let x = 0; x < width; x += 1) {
        const wx = originX + x * waterTintGridStep;
        const tint = normalizeWaterTintSample(getWaterTintAt(wx, wz));
        pixels[ptr] = toColorByte(tint[0]);
        pixels[ptr + 1] = toColorByte(tint[1]);
        pixels[ptr + 2] = toColorByte(tint[2]);
        pixels[ptr + 3] = toColorByte(tint[3]);
        ptr += 4;
      }
    }
    gl.activeTexture(gl.TEXTURE1);
    gl.bindTexture(gl.TEXTURE_2D, waterTintTexture);
    gl.texImage2D(
      gl.TEXTURE_2D,
      0,
      gl.RGBA,
      width,
      height,
      0,
      gl.RGBA,
      gl.UNSIGNED_BYTE,
      pixels,
    );
    gl.activeTexture(gl.TEXTURE0);
    waterTintState.centerCx = centerCx;
    waterTintState.centerCz = centerCz;
    waterTintState.renderDistance = renderDistance;
    waterTintState.originX = originX;
    waterTintState.originZ = originZ;
    waterTintState.width = width;
    waterTintState.height = height;
    waterTintState.step = waterTintGridStep;
    waterTintState.valid = true;
  };
  if (waterTintTexture) {
    gl.activeTexture(gl.TEXTURE1);
    gl.bindTexture(gl.TEXTURE_2D, waterTintTexture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texImage2D(
      gl.TEXTURE_2D,
      0,
      gl.RGBA,
      1,
      1,
      0,
      gl.RGBA,
      gl.UNSIGNED_BYTE,
      new Uint8Array([255, 255, 255, 255]),
    );
    gl.activeTexture(gl.TEXTURE0);
  }

  const aPosition = gl.getAttribLocation(program, "aPosition");
  const aColor = gl.getAttribLocation(program, "aColor");
  const aUv = gl.getAttribLocation(program, "aUv");
  const aLayer = gl.getAttribLocation(program, "aLayer");
  const uMvp = gl.getUniformLocation(program, "uMvp");
  const uCameraPosition = gl.getUniformLocation(program, "uCameraPosition");
  const uTex = gl.getUniformLocation(program, "uTex");
  const uDebugSolid = gl.getUniformLocation(program, "uDebugSolid");
  const uFogColor = gl.getUniformLocation(program, "uFogColor");
  const uFogNear = gl.getUniformLocation(program, "uFogNear");
  const uFogFar = gl.getUniformLocation(program, "uFogFar");
  const waterPosition = gl.getAttribLocation(waterProgram, "aPosition");
  const waterColor = gl.getAttribLocation(waterProgram, "aColor");
  const waterUv = gl.getAttribLocation(waterProgram, "aUv");
  const waterLayerAttrib = gl.getAttribLocation(waterProgram, "aLayer");
  const waterMvp = gl.getUniformLocation(waterProgram, "uMvp");
  const waterCameraPosition = gl.getUniformLocation(waterProgram, "uCameraPosition");
  const waterTex = gl.getUniformLocation(waterProgram, "uTex");
  const waterTintTex = gl.getUniformLocation(waterProgram, "uWaterTintTex");
  const waterFogColor = gl.getUniformLocation(waterProgram, "uFogColor");
  const waterFogNear = gl.getUniformLocation(waterProgram, "uFogNear");
  const waterFogFar = gl.getUniformLocation(waterProgram, "uFogFar");
  const waterTintOrigin = gl.getUniformLocation(waterProgram, "uWaterTintOrigin");
  const waterTintInvSize = gl.getUniformLocation(waterProgram, "uWaterTintInvSize");
  const waterTintStep = gl.getUniformLocation(waterProgram, "uWaterTintStep");
  const waterUnderwater = gl.getUniformLocation(waterProgram, "uUnderwater");
  const leafPosition = gl.getAttribLocation(leafProgram, "aPosition");
  const leafColor = gl.getAttribLocation(leafProgram, "aColor");
  const leafUv = gl.getAttribLocation(leafProgram, "aUv");
  const leafLayer = gl.getAttribLocation(leafProgram, "aLayer");
  const leafMvp = gl.getUniformLocation(leafProgram, "uMvp");
  const leafCameraPosition = gl.getUniformLocation(leafProgram, "uCameraPosition");
  const leafTex = gl.getUniformLocation(leafProgram, "uTex");
  const leafDebugSolid = gl.getUniformLocation(leafProgram, "uDebugSolid");
  const leafFogColor = gl.getUniformLocation(leafProgram, "uFogColor");
  const leafFogNear = gl.getUniformLocation(leafProgram, "uFogNear");
  const leafFogFar = gl.getUniformLocation(leafProgram, "uFogFar");
  const leafTint = gl.getUniformLocation(leafProgram, "uLeafTint");

  const outlinePosition = gl.getAttribLocation(outlineProgram, "aPosition");
  const outlineMvp = gl.getUniformLocation(outlineProgram, "uMvp");
  const outlineOffset = gl.getUniformLocation(outlineProgram, "uOffset");
  const outlineViewOffset = gl.getUniformLocation(outlineProgram, "uViewOffset");
  const outlineColor = gl.getUniformLocation(outlineProgram, "uColor");
  const ensureWorldVao = (meshPart) => {
    if (meshPart.vaoWorld) return meshPart.vaoWorld;
    const vao = gl.createVertexArray();
    if (!vao) return null;
    gl.bindVertexArray(vao);
    gl.bindBuffer(gl.ARRAY_BUFFER, meshPart.positionBuffer);
    gl.enableVertexAttribArray(aPosition);
    gl.vertexAttribPointer(aPosition, 3, gl.FLOAT, false, 0, 0);
    gl.bindBuffer(gl.ARRAY_BUFFER, meshPart.colorBuffer);
    gl.enableVertexAttribArray(aColor);
    gl.vertexAttribPointer(aColor, 4, gl.FLOAT, false, 0, 0);
    gl.bindBuffer(gl.ARRAY_BUFFER, meshPart.uvBuffer);
    gl.enableVertexAttribArray(aUv);
    gl.vertexAttribPointer(aUv, 2, gl.FLOAT, false, 0, 0);
    gl.bindBuffer(gl.ARRAY_BUFFER, meshPart.layerBuffer);
    gl.enableVertexAttribArray(aLayer);
    gl.vertexAttribPointer(aLayer, 1, gl.FLOAT, false, 0, 0);
    gl.bindVertexArray(null);
    meshPart.vaoWorld = vao;
    return vao;
  };
  const ensureWaterVao = (meshPart) => {
    if (meshPart.vaoWater) return meshPart.vaoWater;
    const vao = gl.createVertexArray();
    if (!vao) return null;
    gl.bindVertexArray(vao);
    gl.bindBuffer(gl.ARRAY_BUFFER, meshPart.positionBuffer);
    gl.enableVertexAttribArray(waterPosition);
    gl.vertexAttribPointer(waterPosition, 3, gl.FLOAT, false, 0, 0);
    gl.bindBuffer(gl.ARRAY_BUFFER, meshPart.colorBuffer);
    gl.enableVertexAttribArray(waterColor);
    gl.vertexAttribPointer(waterColor, 4, gl.FLOAT, false, 0, 0);
    gl.bindBuffer(gl.ARRAY_BUFFER, meshPart.uvBuffer);
    gl.enableVertexAttribArray(waterUv);
    gl.vertexAttribPointer(waterUv, 2, gl.FLOAT, false, 0, 0);
    gl.bindBuffer(gl.ARRAY_BUFFER, meshPart.layerBuffer);
    gl.enableVertexAttribArray(waterLayerAttrib);
    gl.vertexAttribPointer(waterLayerAttrib, 1, gl.FLOAT, false, 0, 0);
    gl.bindVertexArray(null);
    meshPart.vaoWater = vao;
    return vao;
  };
  const ensureLeafVao = (meshPart) => {
    if (meshPart.vaoLeaf) return meshPart.vaoLeaf;
    const vao = gl.createVertexArray();
    if (!vao) return null;
    gl.bindVertexArray(vao);
    gl.bindBuffer(gl.ARRAY_BUFFER, meshPart.positionBuffer);
    gl.enableVertexAttribArray(leafPosition);
    gl.vertexAttribPointer(leafPosition, 3, gl.FLOAT, false, 0, 0);
    gl.bindBuffer(gl.ARRAY_BUFFER, meshPart.colorBuffer);
    gl.enableVertexAttribArray(leafColor);
    gl.vertexAttribPointer(leafColor, 4, gl.FLOAT, false, 0, 0);
    gl.bindBuffer(gl.ARRAY_BUFFER, meshPart.uvBuffer);
    gl.enableVertexAttribArray(leafUv);
    gl.vertexAttribPointer(leafUv, 2, gl.FLOAT, false, 0, 0);
    gl.bindBuffer(gl.ARRAY_BUFFER, meshPart.layerBuffer);
    gl.enableVertexAttribArray(leafLayer);
    gl.vertexAttribPointer(leafLayer, 1, gl.FLOAT, false, 0, 0);
    gl.bindVertexArray(null);
    meshPart.vaoLeaf = vao;
    return vao;
  };

  gl.useProgram(program);
  gl.uniform1i(uTex, 0);
  gl.uniform1f(uDebugSolid, window.mcDebugSolid ? 1.0 : 0.0);
  gl.useProgram(waterProgram);
  gl.uniform1i(waterTex, 0);
  gl.uniform1i(waterTintTex, 1);
  gl.uniform2f(waterTintOrigin, 0, 0);
  gl.uniform2f(waterTintInvSize, 1, 1);
  gl.uniform1f(waterTintStep, 0);
  gl.uniform1f(waterUnderwater, 0);
  gl.useProgram(leafProgram);
  gl.uniform1i(leafTex, 0);
  gl.uniform1f(leafDebugSolid, window.mcDebugSolid ? 1.0 : 0.0);

  const getBlockId = (wx, wy, wz) =>
    getBlockIdAtOrDefault(chunkDatas, size, wx, wy, wz, airLongId);
  const player = createPlayerController({ canvas });
  let currentGameFrame = {
    player: player.state,
    inventory: typeof window.mcPlayerInventorySnapshot === "function"
      ? window.mcPlayerInventorySnapshot()
      : null,
  };
  let syncInventorySnapshot = () => { };
  let lastFrameTime = performance.now();
  const getInventorySnapshot = () => currentGameFrame?.inventory ?? null;
  const getRenderDistance = () => {
    const value = Number(currentGameFrame?.render_distance);
    return Number.isInteger(value) && value >= 0
      ? value
      : (window.mcRenderDistance ?? 2);
  };
  const getGameMode = () => normalizeGameMode(getInventorySnapshot()?.game_mode);
  const setGameMode = (mode) => {
    const next = normalizeGameMode(mode);
    const prev = getGameMode();
    if (prev === next) {
      return next;
    }
    const snapshot = typeof window.mcSetPlayerGameMode === "function"
      ? window.mcSetPlayerGameMode(next)
      : null;
    return normalizeGameMode(snapshot?.game_mode ?? next);
  };

  const debugHud = document.createElement("div");
  debugHud.style.position = "fixed";
  debugHud.style.left = "8px";
  debugHud.style.top = "8px";
  debugHud.style.color = "#ffffff";
  debugHud.style.font = "12px monospace";
  debugHud.style.background = "rgba(0, 0, 0, 0.4)";
  debugHud.style.padding = "4px 6px";
  debugHud.style.whiteSpace = "pre-line";
  debugHud.style.pointerEvents = "none";
  document.body.appendChild(debugHud);

  const crosshair = document.createElement("div");
  crosshair.style.position = "fixed";
  crosshair.style.left = "50%";
  crosshair.style.top = "50%";
  crosshair.style.width = "14px";
  crosshair.style.height = "14px";
  crosshair.style.marginLeft = "-7px";
  crosshair.style.marginTop = "-7px";
  crosshair.style.pointerEvents = "none";
  crosshair.style.opacity = "0.85";
  crosshair.style.filter = "drop-shadow(0 0 1px rgba(0,0,0,0.8))";
  crosshair.style.background =
    "linear-gradient(#fff,#fff),linear-gradient(#fff,#fff)";
  crosshair.style.backgroundSize = "2px 14px,14px 2px";
  crosshair.style.backgroundPosition = "center,center";
  crosshair.style.backgroundRepeat = "no-repeat";
  document.body.appendChild(crosshair);

  const hotbar = createHotbarUI({ parent: document.body, canvas });
  hotbar.loadImages().catch((err) => {
    console.error("hotbar load failed", err);
  });
  window.mcHotbar = hotbar;

  const applyGameFrame = (frame) => {
    if (!frame?.chunk || !frame?.player || !frame?.inventory) {
      throw new Error("MoonBit game runtime emitted an invalid frame");
    }
    // Player pose is the only state that changes every frame; apply it cheaply.
    // Inventory/UI state only changes in response to JS events, so it is applied
    // by those event handlers rather than re-synced to the DOM every frame.
    currentGameFrame = frame;
    player.sync(frame.player);
    const cx = Math.floor(player.state.position[0] / size);
    const cz = Math.floor(player.state.position[2] / size);
    const renderDistance = getRenderDistance();
    if (hasWaterTintLookup &&
      (waterTintState.centerCx !== cx ||
        waterTintState.centerCz !== cz ||
        waterTintState.renderDistance !== renderDistance)) {
      rebuildWaterTintTexture(cx, cz, renderDistance);
    }
    for (const key of frame.chunk.evicted ?? []) {
      const mesh = chunkMeshes.get(key);
      if (mesh) deleteChunkMesh(mesh);
      chunkMeshes.delete(key);
    }
    for (const command of frame.chunk.mesh_updates ?? []) {
      applyMeshCommand(command);
    }
    for (const command of frame.chunk.recolors ?? []) {
      if (!applyRecolorCommand(command)) {
        console.error("[lighting] failed to apply recolor command", command);
      }
    }
    if (typeof frame.save === "string") {
      persistSave(frame.save);
    }
  };

  const tickGame = (delta, now, active) => {
    const tick = window.mcTickGame;
    if (typeof tick !== "function") {
      throw new Error("MoonBit game runtime tick is unavailable");
    }
    player.applyIntent(active);
    applyGameFrame(tick(blockRegistry, delta, now));
  };

  const padItems = (items, limit) => {
    const out = Array.isArray(items)
      ? items.slice(0, typeof limit === "number" ? limit : items.length)
      : [];
    if (typeof limit === "number") {
      while (out.length < limit) out.push(null);
    }
    return out;
  };

  const cloneTextureRef = (value) => ({
    name: typeof value?.name === "string" ? value.name : "",
  });

  const cloneUiItem = (item) => {
    if (!item || typeof item !== "object") return null;
    return {
      name: typeof item.name === "string" ? item.name : "air",
      kind: typeof item.kind === "string" ? item.kind : "flat",
      shape: typeof item.shape === "string" ? item.shape : "normal",
      material: typeof item.material === "string" ? item.material : "normal",
      category: typeof item.category === "string" ? item.category : "none",
      top: cloneTextureRef(item.top),
      side: cloneTextureRef(item.side),
      bottom: cloneTextureRef(item.bottom),
      texture: cloneTextureRef(item.texture),
    };
  };

  const normalizeUiHotbarItems = (items) =>
    padItems(Array.isArray(items) ? items.map(cloneUiItem) : [], HOTBAR_SLOT_COUNT);

  const reportMissingTextures = (items, scope) => {
    if (!textures?.textureIndex) return;
    const missing = new Set();
    for (const item of items) {
      if (!item) continue;
      if (item.kind === "flat") {
        const name = item.texture?.name;
        if (name && !textures.textureIndex.has(name)) missing.add(name);
      } else if (item.kind === "block") {
        const names = [
          item.top?.name,
          item.side?.name,
          item.bottom?.name,
        ];
        for (const name of names) {
          if (name && !textures.textureIndex.has(name)) missing.add(name);
        }
      }
    }
    if (missing.size > 0) {
      console.warn(`[textures] missing names in ${scope}:`, Array.from(missing));
    }
  };

  const initialInventorySnapshot = getInventorySnapshot();
  const restoredHotbarSlots = Array.isArray(initialInventorySnapshot?.hotbar_slots)
    ? initialInventorySnapshot.hotbar_slots
    : [];
  const hasRestoredHotbar = restoredHotbarSlots.some((slot) => slot != null);
  let hotbarViewItems = padItems(
    hasRestoredHotbar
      ? restoredHotbarSlots
      : (window.mcCollectHotbarItems?.() ?? []),
    HOTBAR_SLOT_COUNT,
  );
  const isInventoryOpen = () => getInventorySnapshot()?.inventory_open === true;
  window.mcInventoryOpen = isInventoryOpen();
  const chat = createChatUI({
    parent: document.body,
    canOpen: () => !isInventoryOpen(),
    onOpen: () => {
      if (document.pointerLockElement) document.exitPointerLock();
      crosshair.style.display = "none";
    },
    onClose: () => {
      if (isInventoryOpen()) return;
      crosshair.style.display = "block";
      canvas.focus();
      canvas.requestPointerLock();
    },
    onSubmit: (text) => {
      if (!text.trimStart().startsWith("/")) return null;
      const executeCommand = window.mcExecuteCommand;
      if (typeof executeCommand !== "function") {
        return { success: false, message: "Command runtime is unavailable" };
      }
      const result = executeCommand(text);
      return {
        success: result?.success === true,
        message: typeof result?.message === "string"
          ? result.message
          : "Command did not return a result",
      };
    },
  });
  const uiItemsByName = new Map();
  const uiItemKey = (name, category) => `${category ?? "none"}:${name ?? ""}`;
  const indexUiItems = (items) => {
    if (!Array.isArray(items)) return;
    for (const entry of items) {
      const item = cloneUiItem(entry);
      if (!item) continue;
      const key = uiItemKey(item.name, item.category);
      if (!uiItemsByName.has(key)) {
        uiItemsByName.set(key, item);
      }
      if (item.name && item.category !== "none") {
        const fallbackKey = uiItemKey(item.name, "none");
        if (!uiItemsByName.has(fallbackKey)) {
          uiItemsByName.set(fallbackKey, item);
        }
      }
    }
  };
  const resolveSavedHotbarItem = (entry) => {
    if (!entry || typeof entry !== "object") return null;
    if (typeof entry.kind === "string" &&
      typeof entry.shape === "string" &&
      typeof entry.material === "string") {
      return cloneUiItem(entry);
    }
    const name = typeof entry.name === "string" ? entry.name : "";
    if (name.length === 0) return null;
    const category = typeof entry.category === "string" ? entry.category : "none";
    const exact = uiItemsByName.get(uiItemKey(name, category));
    if (exact) return cloneUiItem(exact);
    const byBlock = uiItemsByName.get(uiItemKey(name, "block"));
    if (byBlock) return cloneUiItem(byBlock);
    const byItem = uiItemsByName.get(uiItemKey(name, "item"));
    if (byItem) return cloneUiItem(byItem);
    const byNone = uiItemsByName.get(uiItemKey(name, "none"));
    return byNone ? cloneUiItem(byNone) : null;
  };

  const clampHotbarIndex = (index) => {
    if (!Number.isFinite(Number(index))) return 0;
    return Math.max(0, Math.min(HOTBAR_SLOT_COUNT - 1, Math.floor(Number(index))));
  };

  const getSelectedHotbarIndex = () =>
    clampHotbarIndex(getInventorySnapshot()?.selected_hotbar_index ?? 0);

  const setHotbarItems = (items, writeRuntime = true) => {
    hotbarViewItems = normalizeUiHotbarItems(
      Array.isArray(items)
        ? items.map((entry) => resolveSavedHotbarItem(entry))
        : [],
    );
    indexUiItems(hotbarViewItems);
    reportMissingTextures(hotbarViewItems, "hotbar");
    if (typeof hotbar.setItems === "function") {
      hotbar.setItems(hotbarViewItems, textures);
    }
    if (writeRuntime && typeof window.mcSetPlayerHotbarSlot === "function") {
      hotbarViewItems.forEach((item, index) => {
        window.mcSetPlayerHotbarSlot(index, item?.name ?? "", item?.category ?? "");
      });
    }
  };

  const setHotbarItem = (index, item) => {
    const slot = clampHotbarIndex(index);
    const value = resolveSavedHotbarItem(item);
    if (value && value.category == null) {
      console.error("[hotbar] missing category on item", item);
      return;
    }
    hotbarViewItems[slot] = value;
    indexUiItems([value]);
    if (typeof hotbar.setItem === "function") {
      hotbar.setItem(slot, value, textures);
    } else if (typeof hotbar.setItems === "function") {
      hotbar.setItems(hotbarViewItems, textures);
    }
    if (typeof window.mcSetPlayerHotbarSlot === "function") {
      window.mcSetPlayerHotbarSlot(slot, value?.name ?? "", value?.category ?? "");
    }
  };

  const selectHotbarIndex = (index) => {
    const slot = clampHotbarIndex(index);
    const snapshot = typeof window.mcSelectPlayerHotbar === "function"
      ? window.mcSelectPlayerHotbar(slot)
      : null;
    const selected = clampHotbarIndex(snapshot?.selected_hotbar_index ?? slot);
    if (typeof hotbar.select === "function") {
      hotbar.select(selected);
    } else {
      window.mcHotbarSelectedIndex = selected;
    }
  };

  const inventoryColumns = window.mcInventoryGridX ?? 9;
  const inventoryRows = window.mcInventoryGridY ?? 6;
  const inventoryItems = padItems(
    window.mcCollectInventoryItems?.() ?? [],
    inventoryColumns * inventoryRows,
  );
  indexUiItems(inventoryItems);
  setHotbarItems(hotbarViewItems);
  let setInventoryOpen = (open) => {
    window.mcInventoryOpen = open === true;
  };
  reportMissingTextures(inventoryItems, "inventory");
  const inventory = createInventoryUI({
    parent: document.body,
    textures,
    items: inventoryItems,
    columns: inventoryColumns,
    rows: inventoryRows,
    onSelect: (item) => {
      const slotIndex = getSelectedHotbarIndex();
      const category = item?.category ?? null;
      if (category == null) {
        console.error("[hotbar] missing category on item", item);
        return;
      }
      setHotbarItem(slotIndex, item);
    },
    onClose: () => {
      setInventoryOpen(false);
    },
    onEscape: () => {
      canvas.focus();
      setInventoryOpen(false);
    },
    onToggle: () => {
      setInventoryOpen(!isInventoryOpen());
    },
    canToggle: () => getGameMode() === "creative" && !chat.isOpen(),
  });
  setInventoryOpen = (open, forceRender = false) => {
    const next = open === true;
    if (isInventoryOpen() === next && !forceRender) {
      return;
    }
    const snapshot = typeof window.mcSetPlayerInventoryOpen === "function"
      ? window.mcSetPlayerInventoryOpen(next)
      : null;
    const openState = snapshot?.inventory_open ?? next;
    window.mcInventoryOpen = openState;
    inventory.setOpen(openState);
    if (openState) {
      if (document.pointerLockElement) document.exitPointerLock();
      crosshair.style.display = "none";
    } else if (!chat.isOpen()) {
      crosshair.style.display = "block";
      canvas.focus();
      canvas.requestPointerLock();
    }
  };

  const initialInventory = getInventorySnapshot();
  syncInventorySnapshot = (snapshot) => {
    const next = snapshot ?? initialInventory;
    const items = padItems(next?.hotbar_slots ?? [], HOTBAR_SLOT_COUNT);
    const changed = items.some((item, index) => {
      const current = hotbarViewItems[index];
      return item?.name !== current?.name || item?.category !== current?.category;
    });
    if (changed) {
      setHotbarItems(items, false);
    }
    const selected = clampHotbarIndex(next?.selected_hotbar_index ?? 0);
    if (typeof hotbar.select === "function") {
      hotbar.select(selected);
    }
    const open = next?.inventory_open === true;
    window.mcInventoryOpen = open;
    inventory.setOpen(open);
    crosshair.style.display = open || chat.isOpen() ? "none" : "block";
  };
  syncInventorySnapshot(initialInventory);
  setInventoryOpen(initialInventory?.inventory_open === true, true);
  const persistLatestSave = () => {
    try {
      const flush = window.mcFlushGameSave;
      if (typeof flush !== "function") {
        throw new Error("MoonBit game save encoder is unavailable");
      }
      persistSave(flush(Date.now()));
    } catch (err) {
      console.warn("[save] failed to queue IndexedDB payload", err);
    }
  };
  globalThis.addEventListener("pagehide", persistLatestSave);
  globalThis.document.addEventListener("visibilitychange", () => {
    if (globalThis.document.visibilityState === "hidden") {
      persistLatestSave();
    }
  });
  const markEditedVoxelSections = (wx, wy, wz, keys) => {
    if (!Array.isArray(keys) || keys.length === 0) return;
    if (typeof window.mcMarkChunkBlockChanged === "function") {
      window.mcMarkChunkBlockChanged(wx, wy, wz);
    }
  };

  const drawCamera = {
    position: [0, 0, 0],
    direction: [0, 0, 0],
    center: [0, 0, 0],
  };
  const raycastCamera = {
    position: [0, 0, 0],
    direction: [0, 0, 0],
    center: [0, 0, 0],
  };
  const projMatrix = new Float32Array(16);
  const viewMatrix = new Float32Array(16);
  const mvpMatrix = new Float32Array(16);
  const enableProgramAssert = window.mcDebugProgramAssert === true;
  let biomeHudFrame = 0;
  let biomeHudCached = "Unknown";

  const setBlock = (wx, wy, wz, id) => {
    const keys = setBlockIdAt(chunkDatas, size, wx, wy, wz, id);
    if (!Array.isArray(keys) || keys.length === 0) return false;
    markEditedVoxelSections(wx, wy, wz, keys);
    return true;
  };

  const raycastBlocks = (origin, dir, maxDist = 10, step = 0.05, includeLiquidHit = false) => {
    const res = window.mcRaycastBlocks(
      chunkDatas,
      size,
      origin,
      dir,
      maxDist,
      step,
      airLongId,
      includeLiquidHit,
    );
    if (!res) return null;
    const block = res.block;
    const prev = res.prev == null ? null : res.prev;
    const click = res.click == null ? { _0: 0.5, _1: 0.5, _2: 0.5 } : res.click;
    return { block, prev, click };
  };

  const updateOutline = (camera) => {
    const hit = raycastBlocks(camera.position, camera.direction);
    if (!hit) return null;
    const currentId = getBlockId(hit.block[0], hit.block[1], hit.block[2]);
    if (!Number.isFinite(currentId)) return null;
    if (currentId === airLongId) return null;
    const decoded = unpackLongId(currentId);
    const renderBlock = typeof window.mcGetRenderBlockByLongId === "function"
      ? window.mcGetRenderBlockByLongId(blockRegistry, currentId)
      : null;
    const block = renderBlock && renderBlock.block ? renderBlock.block : null;
    const isSelectable = block && typeof window.mcBlockIsSelectable === "function"
      ? window.mcBlockIsSelectable(block)
      : currentId !== airLongId;
    if (!isSelectable) return null;
    return { pos: hit.block, id: decoded.id, state: decoded.state, longId: currentId };
  };

  const onMouseDown = (event) => {
    if (document.pointerLockElement !== canvas) return;
    event.preventDefault();
    cameraFromYawPitch(
      raycastCamera,
      player.state.position[0],
      player.state.position[1] + 1.65,
      player.state.position[2],
      player.state.yaw,
      player.state.pitch,
    );
    if (event.button === 0) {
      const hit = raycastBlocks(raycastCamera.position, raycastCamera.direction);
      if (!hit) return;
      const slotIndex = getSelectedHotbarIndex();
      const selectedItem = hotbarViewItems[slotIndex];
      const category = selectedItem?.category ?? "none";
      if (selectedItem && selectedItem.category == null) {
        console.error("[hotbar] missing category on item", selectedItem);
        return;
      }
      const useItem = window.mcUseItem;
      const applyUse = window.mcApplyUseAction;
      if (typeof useItem === "function" && typeof applyUse === "function") {
        const action = useItem(selectedItem?.name ?? "", category, hit.block);
        const keys = applyUse(chunkDatas, size, action);
        if (Array.isArray(keys)) {
          markEditedVoxelSections(hit.block[0], hit.block[1], hit.block[2], keys);
        }
      }
    } else if (event.button === 2) {
      const slotIndex = getSelectedHotbarIndex();
      const selectedItem = hotbarViewItems[slotIndex];
      if (!selectedItem) {
        const emptyHit = raycastBlocks(raycastCamera.position, raycastCamera.direction, 10, 0.05, false);
        if (emptyHit && typeof window.mcRequestZombieNavigation === "function") {
          window.mcRequestZombieNavigation(
            chunkDatas, size,
            emptyHit.block[0], emptyHit.block[1], emptyHit.block[2],
          );
        }
        return;
      }
      const category = selectedItem.category;
      if (category == null) {
        console.error("[hotbar] missing category on item", selectedItem);
        return;
      }
      if (category !== "item" && category !== "block") return;
      const includeLiquidHit = selectedItem.name === "bucket";
      const hit = raycastBlocks(
        raycastCamera.position,
        raycastCamera.direction,
        10,
        0.05,
        includeLiquidHit,
      );
      if (!hit || !hit.prev) return;
      const useItemOn = window.mcUseItemOn;
      const applyUseOn = window.mcApplyUseOnAction;
      if (typeof useItemOn === "function" && typeof applyUseOn === "function") {
        const action = useItemOn(selectedItem.name, category, hit.block, hit.prev, hit.click);
        const keys = applyUseOn(
          chunkDatas,
          size,
          action,
          player.state.position,
          player.state.entityHeight ?? 0,
          player.state.entityRadius ?? 0,
        );
        if (Array.isArray(keys)) {
          markEditedVoxelSections(hit.prev[0], hit.prev[1], hit.prev[2], keys);
        }
      }
    }
  };

  canvas.addEventListener("contextmenu", (event) => event.preventDefault());
  canvas.addEventListener("mousedown", onMouseDown);
  if (hotbar?.host) {
    hotbar.host.addEventListener("hotbarselect", (event) => {
      selectHotbarIndex(event.detail?.index ?? 0);
    });
  }

  const assertCurrentProgram = (label, expected) => {
    if (!enableProgramAssert) return;
    const current = gl.getParameter(gl.CURRENT_PROGRAM);
    if (current !== expected) {
      const name = current === program
        ? "world"
        : current === waterProgram
          ? "water"
        : current === leafProgram
          ? "leaf"
          : current === outlineProgram
            ? "outline"
            : "unknown";
      throw new Error(`[gl] ${label}: current program mismatch (${name})`);
    }
  };

  const visibleMeshes = [];
  const normalMeshes = [];
  const leafMeshes = [];
  const translucentMeshes = [];
  const waterMeshes = [];

  function draw() {
    const canvasSize = resizeCanvas(gl, canvas);
    gl.clearColor(0.6, 0.8, 1.0, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.enable(gl.DEPTH_TEST);
    gl.enable(gl.CULL_FACE);
    gl.cullFace(gl.BACK);
    gl.frontFace(gl.CW);

    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D_ARRAY, textureArray);
    if (waterTintTexture) {
      gl.activeTexture(gl.TEXTURE1);
      gl.bindTexture(gl.TEXTURE_2D, waterTintTexture);
      gl.activeTexture(gl.TEXTURE0);
    }

    const now = performance.now();
    const delta = Math.min(0.05, (now - lastFrameTime) / 1000);
    lastFrameTime = now;
    tickGame(delta, now, !isInventoryOpen() && !chat.isOpen());
    window.mcUpdateGltfRenderer(gltfEntityRenderer, delta);
    if (typeof window.mcTickEntityRuntime === "function") {
      window.mcTickEntityRuntime(gltfEntityRenderer, delta);
    }


    const eyeHeight = 1.65;
    const camera = cameraFromYawPitch(
      drawCamera,
      player.state.position[0],
      player.state.position[1] + eyeHeight,
      player.state.position[2],
      player.state.yaw,
      player.state.pitch,
    );
    const isWaterAt = window.mcIsWaterAt;
    const cameraUnderwater = typeof isWaterAt === "function" &&
      isWaterAt(
        chunkDatas,
        size,
        Math.floor(camera.position[0]),
        Math.floor(camera.position[1]),
        Math.floor(camera.position[2]),
      ) === true;
    const outlineBlock = updateOutline(camera);
    const aspect = canvasSize.width / canvasSize.height;
    const fov = (window.mcFov ?? 60) * (Math.PI / 180);
    mat4Perspective(projMatrix, fov, aspect, 0.1, 200.0);
    mat4LookAt(viewMatrix, camera.position, camera.center, UP_VECTOR);
    mat4Mul(mvpMatrix, projMatrix, viewMatrix);
    gl.useProgram(program);
    assertCurrentProgram("world mvp", program);
    gl.uniformMatrix4fv(uMvp, false, mvpMatrix);
    gl.uniform3f(
      uCameraPosition,
      camera.position[0],
      camera.position[1],
      camera.position[2],
    );
    const renderDistance = getRenderDistance();
    const skyFogColor = [0.6, 0.8, 1.0];
    const underwaterFogColor = [0.10, 0.25, 0.48];
    const activeFogColor = cameraUnderwater ? underwaterFogColor : skyFogColor;
    const fogFar = cameraUnderwater
      ? Math.max(8, size * 1.65)
      : (renderDistance + 0.6) * size;
    const fogNear = cameraUnderwater ? fogFar * 0.18 : fogFar * 0.55;
    gl.uniform3f(uFogColor, activeFogColor[0], activeFogColor[1], activeFogColor[2]);
    gl.uniform1f(uFogNear, fogNear);
    gl.uniform1f(uFogFar, fogFar);
    const maxVisibleDist = (renderDistance + 1.2) * size;
    const maxVisibleDistSq = maxVisibleDist * maxVisibleDist;
    const chunkRadius = meshSectionSize * 0.9;
    const coneCos = Math.cos(Math.min(fov * 0.65, Math.PI * 0.95));
    visibleMeshes.length = 0;
    normalMeshes.length = 0;
    leafMeshes.length = 0;
    translucentMeshes.length = 0;
    waterMeshes.length = 0;
    for (const chunkMesh of chunkMeshes.values()) {
      if (!(chunkMesh?.sections instanceof Map)) continue;
      for (const mesh of chunkMesh.sections.values()) {
        const dx = mesh.centerX - camera.position[0];
        const dy = mesh.centerY - camera.position[1];
        const dz = mesh.centerZ - camera.position[2];
        const distSq = dx * dx + dy * dy + dz * dz;
        if (distSq > maxVisibleDistSq) continue;
        const dist = Math.sqrt(distSq);
        if (dist > chunkRadius) {
          const dot = dx * camera.direction[0] +
            dy * camera.direction[1] +
            dz * camera.direction[2];
          if (dot < -chunkRadius) continue;
          if (dot < coneCos * dist - chunkRadius) continue;
        }
        visibleMeshes.push(mesh);
        if (mesh.normal?.count > 0) normalMeshes.push(mesh.normal);
        if (mesh.leaf?.count > 0) leafMeshes.push(mesh.leaf);
        if (mesh.translucent?.count > 0) {
          mesh.translucent.renderDistanceSq = distSq;
          translucentMeshes.push(mesh.translucent);
        }
        if (mesh.water?.count > 0) {
          mesh.water.renderDistanceSq = distSq;
          waterMeshes.push(mesh.water);
        }
      }
    }

    for (const normal of normalMeshes) {
      const vao = ensureWorldVao(normal);
      if (!vao) continue;
      gl.bindVertexArray(vao);
      gl.drawArrays(gl.TRIANGLES, 0, normal.count);
    }
    gl.bindVertexArray(null);

    const leafTintValue = window.mcOakLeavesDefaultTint;
    if (!Array.isArray(leafTintValue) || leafTintValue.length < 3) {
      throw new Error("mcOakLeavesDefaultTint returned invalid value");
    }
    gl.useProgram(leafProgram);
    assertCurrentProgram("leaf mvp", leafProgram);
    gl.uniformMatrix4fv(leafMvp, false, mvpMatrix);
    gl.uniform3f(
      leafCameraPosition,
      camera.position[0],
      camera.position[1],
      camera.position[2],
    );
    gl.uniform3f(leafFogColor, activeFogColor[0], activeFogColor[1], activeFogColor[2]);
    gl.uniform1f(leafFogNear, fogNear);
    gl.uniform1f(leafFogFar, fogFar);
    gl.uniform3f(leafTint, leafTintValue[0], leafTintValue[1], leafTintValue[2]);

    for (const leaf of leafMeshes) {
      const vao = ensureLeafVao(leaf);
      if (!vao) continue;
      gl.bindVertexArray(vao);
      gl.drawArrays(gl.TRIANGLES, 0, leaf.count);
    }
    gl.bindVertexArray(null);

    gl.useProgram(program);
    assertCurrentProgram("translucent mvp", program);

    if (translucentMeshes.length > 0) {
      translucentMeshes.sort((a, b) => b.renderDistanceSq - a.renderDistanceSq);
      gl.enable(gl.BLEND);
      gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
      gl.depthMask(false);
      for (const translucent of translucentMeshes) {
        const vao = ensureWorldVao(translucent);
        if (!vao) continue;
        gl.bindVertexArray(vao);
        gl.drawArrays(gl.TRIANGLES, 0, translucent.count);
      }
      gl.bindVertexArray(null);
      gl.depthMask(true);
      gl.disable(gl.BLEND);
    }

    gl.useProgram(waterProgram);
    assertCurrentProgram("water mvp", waterProgram);
    gl.uniformMatrix4fv(waterMvp, false, mvpMatrix);
    gl.uniform3f(
      waterCameraPosition,
      camera.position[0],
      camera.position[1],
      camera.position[2],
    );
    gl.uniform3f(waterFogColor, activeFogColor[0], activeFogColor[1], activeFogColor[2]);
    gl.uniform1f(waterFogNear, fogNear);
    gl.uniform1f(waterFogFar, fogFar);
    gl.uniform1f(waterUnderwater, cameraUnderwater ? 1.0 : 0.0);
    if (waterTintState.valid && waterTintState.width > 0 && waterTintState.height > 0) {
      gl.uniform2f(waterTintOrigin, waterTintState.originX, waterTintState.originZ);
      gl.uniform2f(
        waterTintInvSize,
        1 / waterTintState.width,
        1 / waterTintState.height,
      );
      gl.uniform1f(waterTintStep, waterTintState.step);
    } else {
      gl.uniform2f(waterTintOrigin, 0, 0);
      gl.uniform2f(waterTintInvSize, 1, 1);
      gl.uniform1f(waterTintStep, 0);
    }
    if (waterMeshes.length > 0) {
      waterMeshes.sort((a, b) => b.renderDistanceSq - a.renderDistanceSq);
      gl.enable(gl.BLEND);
      gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
      gl.depthMask(false);
      for (const water of waterMeshes) {
        const vao = ensureWaterVao(water);
        if (!vao) continue;
        gl.bindVertexArray(vao);
        gl.drawArrays(gl.TRIANGLES, 0, water.count);
      }
      gl.bindVertexArray(null);
      gl.depthMask(true);
      gl.disable(gl.BLEND);
    }

    window.mcRenderGltfRenderer(
      gltfEntityRenderer,
      viewMatrix,
      mvpMatrix,
      camera.position,
      activeFogColor,
      fogNear,
      fogFar,
    );

    if (outlineBlock) {
      gl.useProgram(outlineProgram);
      assertCurrentProgram("outline mvp", outlineProgram);
      gl.uniformMatrix4fv(outlineMvp, false, mvpMatrix);
      const desc = getBlockShapeDesc(outlineBlock.longId);
      let boxes = desc?.boxes;
      if (desc && Number.isFinite(desc.facing) && desc.facing >= 0) {
        const torchBox = getTorchShapeBoxByState(desc.facing);
        if (torchBox) {
          boxes = [torchBox];
        }
      }
      const outlineBias = 0.006;
      gl.uniform3f(
        outlineViewOffset,
        -camera.direction[0] * outlineBias,
        -camera.direction[1] * outlineBias,
        -camera.direction[2] * outlineBias,
      );
      gl.uniform4f(outlineColor, 0.0, 0.0, 0.0, 1.0);
      gl.depthFunc(gl.LEQUAL);
      gl.depthMask(false);
      gl.lineWidth(4);
      const toDraw = Array.isArray(boxes) && boxes.length > 0
        ? boxes
        : [{ min: [0, 0, 0], max: [1, 1, 1] }];
      for (const box of toDraw) {
        const outline = getOutlineBuffer(box);
        gl.uniform3f(outlineOffset, outlineBlock.pos[0], outlineBlock.pos[1], outlineBlock.pos[2]);
        gl.bindBuffer(gl.ARRAY_BUFFER, outline.buffer);
        gl.enableVertexAttribArray(outlinePosition);
        gl.vertexAttribPointer(outlinePosition, 3, gl.FLOAT, false, 0, 0);
        gl.drawArrays(gl.LINES, 0, outline.count);
      }
      gl.lineWidth(1);
      gl.depthMask(true);
      gl.depthFunc(gl.LESS);
      gl.useProgram(program);
    }

    const cx = Math.floor(player.state.position[0] / size);
    const cz = Math.floor(player.state.position[2] / size);
    if ((biomeHudFrame & 7) === 0) {
      biomeHudCached = typeof window.mcGetBiomeName === "function"
        ? window.mcGetBiomeName(
          Math.floor(player.state.position[0]),
          Math.floor(player.state.position[2]),
        )
        : "Unknown";
    }
    biomeHudFrame += 1;
    debugHud.textContent =
      `X: ${player.state.position[0].toFixed(0)} ` +
      `Y: ${player.state.position[1].toFixed(0)} ` +
      `Z: ${player.state.position[2].toFixed(0)} ` +
      `| C: ${cx},${cz} ` +
      `| Biome: ${biomeHudCached} ` +
      `| RD: ${renderDistance} ` +
      `| Loaded: ${chunkDatas.size} ` +
      `| Chunks: ${chunkMeshes.size} ` +
      `| Visible: ${visibleMeshes.length} ` + UPDATE_LABEL +
      `\nClient build: ${CLIENT_BUILD_TIME}`;
    requestAnimationFrame(draw);
  }

  draw();
}

export {
  renderTestChunk,
};
