import {
  cameraFromYawPitch,
  createPlayerController,
} from "./player-controller.js";
import { createHotbarUI } from "./hotbar-ui.js";
import { packLongId, unpackLongId } from "./block-registry.js";
import { logOnce } from "./logging.js";

function collectTorchBounds() {
  const fn = window.mcCollectTorchBounds;
  if (typeof fn !== "function") {
    logOnce("error", "torch-bounds:missing", "[torch-bounds] mcCollectTorchBounds is not available");
    return null;
  }
  const data = fn();
  if (!Array.isArray(data) || data.length < 10) {
    logOnce("error", "torch-bounds:invalid", "[torch-bounds] invalid bounds data", data);
    return null;
  }
  return data;
}

function getTorchOutlinePad() {
  const fn = window.mcGetTorchOutlinePad;
  if (typeof fn !== "function") {
    logOnce("error", "torch-bounds:pad-missing", "[torch-bounds] mcGetTorchOutlinePad is not available");
    return null;
  }
  return fn();
}

function createTorchBounds() {
  const data = collectTorchBounds();
  if (!data) {
    throw new Error("torch bounds unavailable from MoonBit");
  }
  const floor = { min: data[0], max: data[1] };
  const wall = {
    north: { min: data[2], max: data[3] },
    south: { min: data[4], max: data[5] },
    west: { min: data[6], max: data[7] },
    east: { min: data[8], max: data[9] },
  };
  return { floor, wall };
}

function createTorchOutlines(gl) {
  const bounds = createTorchBounds();
  const pad = getTorchOutlinePad();
  if (!pad) {
    throw new Error("torch outline pad unavailable from MoonBit");
  }
  const outlines = {
    floor: createOutlineBuffer(gl, bounds.floor, pad),
    north: createOutlineBuffer(gl, bounds.wall.north, pad),
    south: createOutlineBuffer(gl, bounds.wall.south, pad),
    west: createOutlineBuffer(gl, bounds.wall.west, pad),
    east: createOutlineBuffer(gl, bounds.wall.east, pad),
  };
  return { bounds, outlines };
}

function torchBoundsByState(bounds, state) {
  switch (state) {
    case 1:
      return bounds.wall.north;
    case 2:
      return bounds.wall.south;
    case 3:
      return bounds.wall.west;
    case 4:
      return bounds.wall.east;
    default:
      return bounds.floor;
  }
}

function torchOutlineByState(outlines, state) {
  switch (state) {
    case 1:
      return outlines.north;
    case 2:
      return outlines.south;
    case 3:
      return outlines.west;
    case 4:
      return outlines.east;
    default:
      return outlines.floor;
  }
}

function torchStateFromPlacement(block, prev) {
  if (!block || !prev) return 0;
  const dx = block[0] - prev[0];
  const dy = block[1] - prev[1];
  const dz = block[2] - prev[2];
  if (dy === 1) return 0;
  if (dz === -1) return 1;
  if (dz === 1) return 2;
  if (dx === -1) return 3;
  if (dx === 1) return 4;
  return 0;
}

window.mcGameMode = "creative" // "spectator"

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

function mat4Perspective(fovy, aspect, near, far) {
  const f = 1.0 / Math.tan(fovy / 2.0);
  const nf = 1 / (near - far);
  return [
    f / aspect, 0, 0, 0,
    0, f, 0, 0,
    0, 0, (far + near) * nf, -1,
    0, 0, (2 * far * near) * nf, 0,
  ];
}

function vec3Subtract(a, b) {
  return [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
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

function createBlockInfoMap() {
  const collect = window.mcCollectBlockLightInfo;
  if (typeof collect !== "function") return new Map();
  let entries = [];
  try {
    entries = collect();
  } catch (err) {
    console.warn("mcCollectBlockLightInfo failed", err);
    return new Map();
  }
  const map = new Map();
  if (!Array.isArray(entries)) return map;
  for (const entry of entries) {
    if (!Array.isArray(entry) || entry.length < 3) continue;
    const longId = Number(entry[0]);
    if (!Number.isFinite(longId)) continue;
    const opacity = Number.isFinite(entry[1]) ? Number(entry[1]) : 15;
    const luminance = Number.isFinite(entry[2]) ? Number(entry[2]) : 0;
    map.set(longId, {
      opacity,
      luminance,
      isOpaque: opacity === 15,
      isTransparent: opacity === 0,
    });
  }
  return map;
}

function getLongIdByName(name) {
  const fn = window.mcGetLongIdByName;
  if (typeof fn !== "function") {
    logOnce("error", "block:getLongId-missing", "[block] mcGetLongIdByName not available");
    return null;
  }
  const value = fn(name);
  const num = Number(value);
  return Number.isFinite(num) ? num : null;
}

function getAirLongId() {
  const fn = window.mcGetAirLongId;
  if (typeof fn !== "function") {
    logOnce("error", "block:getAirLongId-missing", "[block] mcGetAirLongId not available");
    return 0;
  }
  const value = fn();
  const num = Number(value);
  return Number.isFinite(num) ? num : 0;
}

function getIdByName(name) {
  const longId = getLongIdByName(name);
  if (!Number.isFinite(longId)) return null;
  return unpackLongId(longId).id;
}

function collectHotbarDefs() {
  const fn = window.mcCollectHotbarDefs;
  if (typeof fn !== "function") {
    logOnce("error", "hotbar:collect-missing", "[hotbar] mcCollectHotbarDefs not available");
    return [];
  }
  const defs = fn();
  if (!Array.isArray(defs)) {
    logOnce("error", "hotbar:collect-invalid", "[hotbar] mcCollectHotbarDefs returned non-array", defs);
    return [];
  }
  return defs
    .filter((def) => Array.isArray(def) && def.length >= 7)
    .map((def) => ({
      name: String(def[0] ?? ""),
      shape: String(def[1] ?? "normal"),
      kind: String(def[2] ?? "block"),
      top: String(def[3] ?? ""),
      side: String(def[4] ?? ""),
      bottom: String(def[5] ?? ""),
      texture: String(def[6] ?? ""),
    }))
    .filter((def) => def.name.length > 0);
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

function normalizeChunkData(data, fallback) {
  if (!data) return fallback ?? null;
  if (Array.isArray(data)) return data;
  if (data instanceof Uint32Array) return Array.from(data);
  if (typeof data.length === "number") {
    const out = new Array(data.length);
    for (let i = 0; i < data.length; i += 1) {
      out[i] = data[i];
    }
    return out;
  }
  return fallback ?? null;
}

function buildWorldMesh(
  blockRegistry,
  chunkDatas,
  size,
  radius,
  centerX = 0,
  centerZ = 0,
  minY = 0,
  maxY = 0,
) {
  if (typeof window.mcBuildWorldMesh !== "function") {
    throw new Error("mcBuildWorldMesh not available");
  }
  const emptyChunk = new Array(size * size * size).fill(0);
  const emptyLight = new Uint8Array(size * size * size);
  emptyLight.fill(15);
  const entries = [];

  for (let dx = -radius; dx <= radius; dx += 1) {
    for (let dz = -radius; dz <= radius; dz += 1) {
      const cx = centerX + dx;
      const cz = centerZ + dz;
      for (let cy = minY; cy <= maxY; cy += 1) {
        const key = `${cx},${cy},${cz}`;
        const data = normalizeChunkData(chunkDatas.get(key), emptyChunk);
        entries.push({ x: cx, y: cy, z: cz, data, light: emptyLight });
      }
    }
  }

  const mesh = window.mcBuildWorldMesh(blockRegistry, entries, size);
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
  return {
    positions: new Float32Array(mesh.positions),
    uvs: new Float32Array(mesh.uvs),
    layers: new Float32Array(mesh.layers),
    colors,
    normals: new Float32Array(mesh.normals ?? []),
    count: mesh.count,
  };
}

function createCanvas() {
  const canvas = document.createElement("canvas");
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
  chunkData,
  chunkSize,
  chunkGenerator,
}) {
  const canvas = createCanvas();
  const gl = canvas.getContext("webgl2");
  if (!gl) throw new Error("webgl2 not supported");

  const vertexSource = `#version 300 es
    precision highp float;
    precision highp int;
    in vec3 aPosition;
    in vec4 aColor;
    in vec2 aUv;
    in float aLayer;
    uniform mat4 uMvp;
    uniform mat4 uView;
    out vec4 vColor;
    out vec3 vPos;
    out vec2 vUv;
    out float vLayer;
    void main() {
      vUv = aUv;
      vLayer = aLayer;
      vColor = aColor;
      vec4 pos = vec4(aPosition, 1.0);
      vPos = (uView * pos).xyz;
      gl_Position = uMvp * pos;
    }
  `;

  const fragmentSource = `#version 300 es
    precision highp float;
    precision highp sampler2DArray;
    in vec2 vUv;
    in float vLayer;
    in vec3 vPos;
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
      if (color.a <= 0.3) {
        discard;
      }
      float fogDistance = length(vPos);
      float fogAmount = smoothstep(uFogNear, uFogFar, fogDistance);
      vec3 mixed = mix(vColor.rgb * color.rgb, uFogColor, fogAmount);
      outColor = vec4(mixed, color.a * vColor.a);
    }
  `;

  const program = createProgram(gl, vertexSource, fragmentSource);
  const outlineProgram = createOutlineProgram(gl);
  const outlineCube = createOutlineBuffer(gl);
  const torch = createTorchOutlines(gl);
  const torchBounds = torch.bounds;
  const torchOutlines = torch.outlines;
  const size = chunkSize ?? 16;
  let data = normalizeChunkData(chunkData);
  const chunkDatas = new Map();
  if (data) chunkDatas.set("0,0,0", data);
  const pendingChunks = new Set();
  const chunkQueue = [];
  const chunkMeshes = new Map();
  const maxGenPerFrame = window.mcChunkGenPerFrame ?? 2;
  const maxMeshBuildPerFrame = window.mcMeshBuildPerFrame ?? 2;
  const worldMinY = window.mcWorldMinY ?? 0;
  const worldMaxY = window.mcWorldMaxY ?? 0;
  const chunkMinY = Math.floor(worldMinY / size);
  const chunkMaxY = Math.floor(worldMaxY / size);
  console.debug("[spawn] world bounds", {
    worldMinY,
    worldMaxY,
    chunkMinY,
    chunkMaxY,
    size,
  });

  // Lighting disabled; face shading is baked into mesh colors.

  const fallbackChunk = new Array(size * size * size).fill(0);
  const fallbackLight = new Uint8Array(size * size * size);
  fallbackLight.fill(15);
  const enqueueChunk = (cx, cy, cz) => {
    const key = `${cx},${cy},${cz}`;
    if (chunkDatas.has(key) || pendingChunks.has(key)) return;
    pendingChunks.add(key);
    chunkQueue.push({ key, cx, cy, cz });
  };

  const buildChunkMesh = (key, cx, cy, cz, data) => {
    if (typeof window.mcBuildWorldMesh !== "function") {
      logOnce("error", "mesh:build-missing", "[mesh] mcBuildWorldMesh not available");
      return;
    }
    const light = fallbackLight;
    const entries = [{ x: cx, y: cy, z: cz, data, light }];
    const mesh = window.mcBuildWorldMesh(blockRegistry, entries, size);
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
    const normals = new Float32Array(mesh.normals ?? []);
    const positionBuffer = gl.createBuffer();
    const uvBuffer = gl.createBuffer();
    const layerBuffer = gl.createBuffer();
    const colorBuffer = gl.createBuffer();
    const normalBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, positions, gl.STATIC_DRAW);
    gl.bindBuffer(gl.ARRAY_BUFFER, colorBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, colors, gl.DYNAMIC_DRAW);
    gl.bindBuffer(gl.ARRAY_BUFFER, normalBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, normals, gl.STATIC_DRAW);
    gl.bindBuffer(gl.ARRAY_BUFFER, uvBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, uvs, gl.STATIC_DRAW);
    gl.bindBuffer(gl.ARRAY_BUFFER, layerBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, layers, gl.STATIC_DRAW);
    chunkMeshes.set(key, {
      cx,
      cy,
      cz,
      count: mesh.count,
      positionBuffer,
      colorBuffer,
      normalBuffer,
      uvBuffer,
      layerBuffer,
    });
  };

  const processChunkQueue = () => {
    if (typeof chunkGenerator !== "function") {
      logOnce("warn", "chunk:generator-missing", "[chunk] chunkGenerator not available");
      return;
    }
    let remaining = maxGenPerFrame;
    while (remaining > 0 && chunkQueue.length > 0) {
      const next = chunkQueue.shift();
      if (!next) break;
      const { key, cx, cy, cz } = next;
      let data = null;
      try {
        data = chunkGenerator(cx, cy, cz);
      } catch (err) {
        console.warn("chunk gen failed", key, err);
      }
      if (window.mcDebugChunkGen) {
        console.log("chunk gen", key, "type:", data?.constructor?.name, "length:", data?.length);
      }
      if (data) {
        data = normalizeChunkData(data);
        if (data) {
          chunkDatas.set(key, data);
        }
      }
      pendingChunks.delete(key);
      remaining -= 1;
    }
  };

  const getChunkData = (cx, cy, cz) => {
    const key = `${cx},${cy},${cz}`;
    const cached = chunkDatas.get(key);
    if (cached) return cached;
    enqueueChunk(cx, cy, cz);
    return fallbackChunk;
  };

  // Return only cached chunk data, without falling back to placeholder air.
  const getChunkDataIfLoaded = (cx, cy, cz) => {
    const key = `${cx},${cy},${cz}`;
    return chunkDatas.get(key) ?? null;
  };

  // Ensure spawn chunk exists before computing surface height.
  if (!chunkDatas.has("0,0,0") && typeof chunkGenerator === "function") {
    try {
      let seedData = chunkGenerator(0, 0, 0);
      seedData = normalizeChunkData(seedData);
      if (seedData) {
        chunkDatas.set("0,0,0", seedData);
        console.debug("[spawn] seed chunk loaded", { key: "0,0,0", len: seedData.length });
      } else {
        console.debug("[spawn] seed chunk empty", { key: "0,0,0" });
      }
    } catch (err) {
      console.warn("spawn chunk gen failed", err);
    }
  }

  const computeSpawn = window.mcComputeSpawnPosition;
  const spawn = typeof computeSpawn === "function"
    ? computeSpawn(
      chunkDatas,
      size,
      chunkMinY,
      chunkMaxY,
      0,
      0,
      Math.floor(size / 2),
      Math.floor(size / 2),
      3,
      size,
      0,
    )
    : {
      position: [Math.floor(size / 2) + 0.5, size + 3, Math.floor(size / 2) + 0.5],
      surfaceY: null,
    };

  const textureArray = createTextureArray(gl, textures);

  const aPosition = gl.getAttribLocation(program, "aPosition");
  const aColor = gl.getAttribLocation(program, "aColor");
  const aUv = gl.getAttribLocation(program, "aUv");
  const aLayer = gl.getAttribLocation(program, "aLayer");
  const uMvp = gl.getUniformLocation(program, "uMvp");
  const uView = gl.getUniformLocation(program, "uView");
  const uTex = gl.getUniformLocation(program, "uTex");
  const uDebugSolid = gl.getUniformLocation(program, "uDebugSolid");
  const uFogColor = gl.getUniformLocation(program, "uFogColor");
  const uFogNear = gl.getUniformLocation(program, "uFogNear");
  const uFogFar = gl.getUniformLocation(program, "uFogFar");

  const outlinePosition = gl.getAttribLocation(outlineProgram, "aPosition");
  const outlineMvp = gl.getUniformLocation(outlineProgram, "uMvp");
  const outlineOffset = gl.getUniformLocation(outlineProgram, "uOffset");
  const outlineViewOffset = gl.getUniformLocation(outlineProgram, "uViewOffset");
  const outlineColor = gl.getUniformLocation(outlineProgram, "uColor");

  gl.useProgram(program);
  gl.uniform1i(uTex, 0);
  gl.uniform1f(uDebugSolid, window.mcDebugSolid ? 1.0 : 0.0);

  const airId = getAirLongId();
  const hotbarDefs = collectHotbarDefs();
  const torchIds = new Set(
    hotbarDefs
      .filter((def) => def.shape === "torch")
      .map((def) => getIdByName(def.name))
      .filter((id) => Number.isFinite(id)),
  );
  const getBlockId = (wx, wy, wz) => {
    const hit = getBlock(wx, wy, wz);
    return hit ? hit.value : null;
  };
  const isSolidBlock = (id) => {
    const selectableFn = window.mcBlockIsSelectable;
    if (typeof selectableFn === "function") {
      return selectableFn(blockRegistry, id);
    }
    return id !== 0;
  };
  const getBlockAabb = (id) => {
    if (id === airId) return null;
    const decoded = unpackLongId(id);
    if (torchIds.has(decoded.id)) {
      return getTorchAabbByState(decoded.state);
    }
    if (typeof isSolidBlock === "function" && !isSolidBlock(id)) {
      return null;
    }
    return { min: [0, 0, 0], max: [1, 1, 1] };
  };
  const player = createPlayerController({
    canvas,
    worldMinY,
    spawnPosition: spawn.position,
    gameMode: window.mcGameMode,
    getBlockAt: getBlockId,
    isSolidBlock,
    getBlockAabb,
  });

  const debugHud = document.createElement("div");
  debugHud.style.position = "fixed";
  debugHud.style.left = "8px";
  debugHud.style.top = "8px";
  debugHud.style.color = "#ffffff";
  debugHud.style.font = "12px monospace";
  debugHud.style.background = "rgba(0, 0, 0, 0.4)";
  debugHud.style.padding = "4px 6px";
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

  const rebuildMeshIfNeeded = () => {
    processChunkQueue();
    const cx = Math.floor(player.state.position[0] / size);
    const cz = Math.floor(player.state.position[2] / size);
    const renderDistance = window.mcRenderDistance ?? 2;
    const nextCenterKey = `${cx},0,${cz}`;
    let missing = false;
    const desiredKeys = new Set();
    for (let dx = -renderDistance; dx <= renderDistance; dx += 1) {
      for (let dz = -renderDistance; dz <= renderDistance; dz += 1) {
        for (let cy = chunkMinY; cy <= chunkMaxY; cy += 1) {
          const key = `${cx + dx},${cy},${cz + dz}`;
          desiredKeys.add(key);
          if (!chunkDatas.has(key)) {
            enqueueChunk(cx + dx, cy, cz + dz);
            missing = true;
          }
        }
      }
    }
    if (missing || nextCenterKey !== player.state.centerKey) {
      player.state.centerKey = nextCenterKey;
    }

    // Drop far chunks to cap memory/draw calls.
    for (const key of chunkMeshes.keys()) {
      if (!desiredKeys.has(key)) {
        chunkMeshes.delete(key);
      }
    }
    for (const key of chunkDatas.keys()) {
      if (!desiredKeys.has(key)) {
        chunkDatas.delete(key);
      }
    }

    let built = 0;
    for (const key of desiredKeys) {
      if (built >= maxMeshBuildPerFrame) break;
      if (chunkMeshes.has(key)) continue;
      const data = chunkDatas.get(key);
      if (!data) continue;
      const parts = key.split(",");
      const kx = Number(parts[0]);
      const ky = Number(parts[1]);
      const kz = Number(parts[2]);
      buildChunkMesh(key, kx, ky, kz, data);
      built += 1;
    }
  };

  const placedBlockIds = hotbarDefs
    .map((def) => getLongIdByName(def.name))
    .filter((id) => Number.isFinite(id));
  window.mcPlacedBlockIds = placedBlockIds;

  const getTorchAabbByState = (state) => torchBoundsByState(torchBounds, state);

  const getPlacedBlockId = (index) => {
    const id = placedBlockIds[index];
    return Number.isFinite(id) ? id : airId;
  };

  const buildHotbarItems = (slotCount) => {
    const items = [];
    for (let i = 0; i < slotCount; i += 1) {
      const def = hotbarDefs[i];
      if (!def) {
        items.push(null);
        continue;
      }
      if (def.kind === "flat") {
        items.push({
          kind: "flat",
          texture: { name: def.texture || "missing_tile" },
        });
      } else {
        items.push({
          kind: "block",
          top: { name: def.top || "missing_tile" },
          side: { name: def.side || def.top || "missing_tile" },
          bottom: { name: def.bottom || "missing_tile" },
        });
      }
    }
    return items;
  };

  if (typeof hotbar.setItems === "function") {
    hotbar.setItems(buildHotbarItems(9), textures);
  }

  const getChunkKey = (cx, cy, cz) => `${cx},${cy},${cz}`;

  const getBlock = (wx, wy, wz) => {
    const cx = Math.floor(wx / size);
    const cy = Math.floor(wy / size);
    const cz = Math.floor(wz / size);
    const key = getChunkKey(cx, cy, cz);
    const data = chunkDatas.get(key);
    if (!data) return null;
    const lx = wx - cx * size;
    const ly = wy - cy * size;
    const lz = wz - cz * size;
    if (lx < 0 || lx >= size || ly < 0 || ly >= size || lz < 0 || lz >= size) {
      return null;
    }
    const idx = (ly * size + lz) * size + lx;
    return { data, key, idx, cx, cy, cz, lx, ly, lz, value: data[idx] };
  };

  const rebuildChunk = (key, cx, cy, cz) => {
    const data = chunkDatas.get(key);
    if (!data) return;
    buildChunkMesh(key, cx, cy, cz, data);
  };

  const rebuildNeighborChunks = (cx, cy, cz, lx, ly, lz) => {
    const neighbors = [];
    if (lx === 0) neighbors.push([cx - 1, cy, cz]);
    if (lx === size - 1) neighbors.push([cx + 1, cy, cz]);
    if (ly === 0) neighbors.push([cx, cy - 1, cz]);
    if (ly === size - 1) neighbors.push([cx, cy + 1, cz]);
    if (lz === 0) neighbors.push([cx, cy, cz - 1]);
    if (lz === size - 1) neighbors.push([cx, cy, cz + 1]);
    for (const [nx, ny, nz] of neighbors) {
      const nkey = getChunkKey(nx, ny, nz);
      if (chunkDatas.has(nkey)) {
        rebuildChunk(nkey, nx, ny, nz);
      }
    }
  };

  const setBlock = (wx, wy, wz, id) => {
    const hit = getBlock(wx, wy, wz);
    if (!hit) return false;
    if (hit.value === id) return false;
    hit.data[hit.idx] = id;
    rebuildChunk(hit.key, hit.cx, hit.cy, hit.cz);
    rebuildNeighborChunks(hit.cx, hit.cy, hit.cz, hit.lx, hit.ly, hit.lz);
    return true;
  };

  const raycastBlocks = (origin, dir, maxDist = 10, step = 0.05) => {
    const raycast = window.mcRaycastBlocks;
    if (typeof raycast === "function") {
      const res = raycast(chunkDatas, size, origin, dir, maxDist, step, airId);
      if (!res) return null;
      const block = Array.isArray(res.block) ? res.block : Array.from(res.block ?? []);
      const prev = res.prev == null || res.prev === null || res.prev === undefined
        ? null
        : (Array.isArray(res.prev) ? res.prev : Array.from(res.prev ?? []));
      return { block, prev };
    }
    logOnce("warn", "raycast:fallback", "[raycast] mcRaycastBlocks not available, using JS fallback");
    let lastPos = null;
    for (let t = 0; t <= maxDist; t += step) {
      const px = origin[0] + dir[0] * t;
      const py = origin[1] + dir[1] * t;
      const pz = origin[2] + dir[2] * t;
      const bx = Math.floor(px);
      const by = Math.floor(py);
      const bz = Math.floor(pz);
      if (!lastPos || bx !== lastPos[0] || by !== lastPos[1] || bz !== lastPos[2]) {
        const hit = getBlock(bx, by, bz);
        if (hit && hit.value !== airId) {
          return { block: [bx, by, bz], prev: lastPos };
        }
        lastPos = [bx, by, bz];
      }
    }
    return null;
  };

  const rayIntersectsAabb = (origin, dir, min, max) => {
    let tmin = -Infinity;
    let tmax = Infinity;
    for (let i = 0; i < 3; i += 1) {
      const o = origin[i];
      const d = dir[i];
      const minV = min[i];
      const maxV = max[i];
      if (Math.abs(d) < 1e-8) {
        if (o < minV || o > maxV) return false;
      } else {
        const inv = 1 / d;
        const t1 = (minV - o) * inv;
        const t2 = (maxV - o) * inv;
        const tNear = Math.min(t1, t2);
        const tFar = Math.max(t1, t2);
        tmin = Math.max(tmin, tNear);
        tmax = Math.min(tmax, tFar);
        if (tmin > tmax) return false;
      }
    }
    return tmax >= 0;
  };

  const updateOutline = (camera) => {
    const hit = raycastBlocks(camera.position, camera.direction);
    if (!hit) return null;
    const current = getBlock(hit.block[0], hit.block[1], hit.block[2]);
    if (!current) return null;
    const decoded = unpackLongId(current.value);
    const selectableFn = window.mcBlockIsSelectable;
    if (typeof selectableFn === "function") {
      const isSelectable = selectableFn(blockRegistry, current.value);
      if (!isSelectable) return null;
    } else if (current.value === airId) {
      return null;
    }
    if (torchIds.has(decoded.id)) {
      const bounds = getTorchAabbByState(decoded.state);
      const min = [
        hit.block[0] + bounds.min[0],
        hit.block[1] + bounds.min[1],
        hit.block[2] + bounds.min[2],
      ];
      const max = [
        hit.block[0] + bounds.max[0],
        hit.block[1] + bounds.max[1],
        hit.block[2] + bounds.max[2],
      ];
      if (!rayIntersectsAabb(camera.position, camera.direction, min, max)) {
        return null;
      }
    }
    return { pos: hit.block, id: decoded.id, state: decoded.state };
  };

  const validateHitAabb = (camera, hit) => {
    if (!hit) return null;
    const current = getBlock(hit.block[0], hit.block[1], hit.block[2]);
    if (!current) return null;
    const decoded = unpackLongId(current.value);
    if (!torchIds.has(decoded.id)) return hit;
    const bounds = getTorchAabbByState(decoded.state);
    const min = [
      hit.block[0] + bounds.min[0],
      hit.block[1] + bounds.min[1],
      hit.block[2] + bounds.min[2],
    ];
    const max = [
      hit.block[0] + bounds.max[0],
      hit.block[1] + bounds.max[1],
      hit.block[2] + bounds.max[2],
    ];
    if (!rayIntersectsAabb(camera.position, camera.direction, min, max)) {
      return null;
    }
    return hit;
  };

  const onMouseDown = (event) => {
    if (document.pointerLockElement !== canvas) return;
    event.preventDefault();
    const eye = [
      player.state.position[0],
      player.state.position[1] + 1.65,
      player.state.position[2],
    ];
    const camera = cameraFromYawPitch(
      [...eye],
      player.state.yaw,
      player.state.pitch,
    );
    const hit = validateHitAabb(camera, raycastBlocks(camera.position, camera.direction));
    if (!hit) return;
    if (event.button === 0) {
      setBlock(hit.block[0], hit.block[1], hit.block[2], airId);
    } else if (event.button === 2) {
      if (!hit.prev) return;
      const target = getBlock(hit.prev[0], hit.prev[1], hit.prev[2]);
      if (target && target.value === airId) {
        const slotIndex = typeof hotbar.getSelectedIndex === "function"
          ? hotbar.getSelectedIndex()
          : (window.mcHotbarSelectedIndex ?? 0);
        const placedId = getPlacedBlockId(slotIndex);
        if (placedId !== airId) {
          const placedDecoded = unpackLongId(placedId);
          if (torchIds.has(placedDecoded.id)) {
            const state = torchStateFromPlacement(hit.block, hit.prev);
            setBlock(
              hit.prev[0],
              hit.prev[1],
              hit.prev[2],
              packLongId(placedDecoded.id, state),
            );
          } else {
            setBlock(hit.prev[0], hit.prev[1], hit.prev[2], placedId);
          }
        }
      }
    }
  };

  canvas.addEventListener("contextmenu", (event) => event.preventDefault());
  canvas.addEventListener("mousedown", onMouseDown);

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

    const now = performance.now();
    const delta = Math.min(0.05, (now - player.state.lastTime) / 1000);
    player.state.lastTime = now;
    player.update(delta);
    rebuildMeshIfNeeded();

    const eyeHeight = 1.65;
    const camera = cameraFromYawPitch(
      [
        player.state.position[0],
        player.state.position[1] + eyeHeight,
        player.state.position[2],
      ],
      player.state.yaw,
      player.state.pitch,
    );
    const outlineBlock = updateOutline(camera);
    const aspect = canvasSize.width / canvasSize.height;
    const fov = (window.mcFov ?? 60) * (Math.PI / 180);
    const proj = mat4Perspective(fov, aspect, 0.1, 200.0);
    const view = mat4LookAt(camera.position, camera.center, [0, 1, 0]);
    const mvp = mat4Multiply(proj, view);
    gl.uniformMatrix4fv(uMvp, false, new Float32Array(mvp));
    gl.uniformMatrix4fv(uView, false, new Float32Array(view));
    gl.uniform3f(uFogColor, 0.6, 0.8, 1.0);
    const renderDistance = window.mcRenderDistance ?? 2;
    const fogFar = (renderDistance + 0.6) * size;
    const fogNear = fogFar * 0.55;
    gl.uniform1f(uFogNear, fogNear);
    gl.uniform1f(uFogFar, fogFar);

    for (const mesh of chunkMeshes.values()) {
      if (mesh.count <= 0) continue;
      gl.bindBuffer(gl.ARRAY_BUFFER, mesh.positionBuffer);
      gl.enableVertexAttribArray(aPosition);
      gl.vertexAttribPointer(aPosition, 3, gl.FLOAT, false, 0, 0);

      gl.bindBuffer(gl.ARRAY_BUFFER, mesh.colorBuffer);
      gl.enableVertexAttribArray(aColor);
      gl.vertexAttribPointer(aColor, 4, gl.FLOAT, false, 0, 0);

      gl.bindBuffer(gl.ARRAY_BUFFER, mesh.uvBuffer);
      gl.enableVertexAttribArray(aUv);
      gl.vertexAttribPointer(aUv, 2, gl.FLOAT, false, 0, 0);

      gl.bindBuffer(gl.ARRAY_BUFFER, mesh.layerBuffer);
      gl.enableVertexAttribArray(aLayer);
      gl.vertexAttribPointer(aLayer, 1, gl.FLOAT, false, 0, 0);

      gl.drawArrays(gl.TRIANGLES, 0, mesh.count);
    }

    if (outlineBlock) {
      gl.useProgram(outlineProgram);
      gl.uniformMatrix4fv(outlineMvp, false, new Float32Array(mvp));
      const outline = torchIds.has(outlineBlock.id)
        ? torchOutlineByState(torchOutlines, outlineBlock.state)
        : outlineCube;
      gl.uniform3f(outlineOffset, outlineBlock.pos[0], outlineBlock.pos[1], outlineBlock.pos[2]);
      const outlineBias = 0.006;
      gl.uniform3f(
        outlineViewOffset,
        -camera.direction[0] * outlineBias,
        -camera.direction[1] * outlineBias,
        -camera.direction[2] * outlineBias,
      );
      gl.uniform4f(outlineColor, 0.0, 0.0, 0.0, 1.0);
      gl.bindBuffer(gl.ARRAY_BUFFER, outline.buffer);
      gl.enableVertexAttribArray(outlinePosition);
      gl.vertexAttribPointer(outlinePosition, 3, gl.FLOAT, false, 0, 0);
      gl.depthFunc(gl.LEQUAL);
      gl.depthMask(false);
      gl.lineWidth(4);
      gl.drawArrays(gl.LINES, 0, outline.count);
      gl.lineWidth(1);
      gl.depthMask(true);
      gl.depthFunc(gl.LESS);
      gl.useProgram(program);
    }

    const cx = Math.floor(player.state.position[0] / size);
    const cz = Math.floor(player.state.position[2] / size);
    debugHud.textContent =
      `X: ${player.state.position[0].toFixed(2)} ` +
      `Y: ${player.state.position[1].toFixed(2)} ` +
      `Z: ${player.state.position[2].toFixed(2)} ` +
      `| C: ${cx},${cz} ` +
      `| Loaded: ${chunkDatas.size}` +
      `| Meshes: ${chunkMeshes.size}`;
    requestAnimationFrame(draw);
  }

  draw();
}

export {
  renderTestChunk,
};
