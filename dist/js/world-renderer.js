import {
  createPlayerController,
} from "./player-controller.js";
import { createHotbarUI } from "./hotbar-ui.js";
import { createInventoryUI } from "./inventory-ui.js";
import { unpackLongId } from "./block-registry.js";
import {
  UP_VECTOR,
  cameraFromYawPitch,
  mat4Perspective,
  mat4LookAt,
  mat4Mul,
} from "./math3d.js";

const UPDATE_LABEL = `(7:26)`
const DEFAULT_MESH_SECTION_SIZE = 8;

function getBlockShapeDesc(longId) {
  const value = window.mcGetBlockShapeDesc(longId);
  return value ?? null;
}

function getTorchShapeBoxByState(state) {
  const value = window.mcTorchShapeBoxByState?.(state);
  if (!value || !Array.isArray(value.min) || !Array.isArray(value.max)) {
    return null;
  }
  return value;
}

window.mcGameMode = "creative" // "spectator"

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

function getBlockIdAt(chunkDatas, size, wx, wy, wz) {
  const value = window.mcGetBlockId(chunkDatas, size, wx, wy, wz);
  const num = Number(value);
  if (!Number.isFinite(num)) {
    throw new Error("mcGetBlockId returned invalid value");
  }
  return num;
}

function setBlockIdAt(chunkDatas, size, wx, wy, wz, id) {
  const value = window.mcSetBlockId(chunkDatas, size, wx, wy, wz, id);
  if (!Array.isArray(value)) {
    throw new Error("mcSetBlockId returned non-array");
  }
  return value;
}

function buildWorldLight(chunkDatas, size, keys, worldMinY, worldMaxY) {
  const fn = window.mcBuildWorldLight;
  if (typeof fn !== "function") {
    return null;
  }
  const entries = fn(chunkDatas, size, keys, worldMinY, worldMaxY);
  if (!Array.isArray(entries)) {
    console.warn("mcBuildWorldLight returned non-array");
    return null;
  }
  return entries;
}

function chunkXyzByKey(key) {
  const out = window.mcChunkXyzByKey(key);
  return { x: Number(out._0) | 0, y: Number(out._1) | 0, z: Number(out._2) | 0 };
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
  chunkData,
  chunkSize,
  chunkGenerator,
}) {
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
      if (color.a * vColor.a <= 0.3) {
        discard;
      }
      float fogDistance = length(vPos);
      float fogAmount = smoothstep(uFogNear, uFogFar, fogDistance);
      vec3 mixed = mix(vColor.rgb * color.rgb, uFogColor, fogAmount);
      outColor = vec4(mixed, color.a * vColor.a);
    }
  `;

  const program = createProgram(gl, vertexSource, fragmentSource);
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
  const size = chunkSize ?? 16;
  let data = normalizeChunkData(chunkData);
  const chunkDatas = new Map();
  if (data) chunkDatas.set("0,0,0", data);
  const pendingChunks = new Set();
  const chunkQueue = [];
  let chunkQueueHead = 0;
  const chunkMeshes = new Map();
  const chunkLights = new Map();
  const dirtyMeshKeys = new Set();
  const dirtySectionKeys = new Set();
  const maxGenPerFrame = window.mcChunkGenPerFrame ?? 2;
  const maxMeshBuildPerFrame = window.mcMeshBuildPerFrame ?? 2;
  const worldMinY = window.mcWorldMinY ?? 0;
  const worldMaxY = window.mcWorldMaxY ?? 0;
  const chunkMinY = Math.floor(worldMinY / size);
  const chunkMaxY = Math.floor(worldMaxY / size);
  const useFixedLight = window.mcUseFixedLight === true;
  const meshSectionRaw = Number(window.mcMeshSectionSize ?? DEFAULT_MESH_SECTION_SIZE);
  const meshSectionCandidate = Number.isFinite(meshSectionRaw)
    ? Math.max(1, Math.floor(meshSectionRaw))
    : DEFAULT_MESH_SECTION_SIZE;
  const meshSectionSize = size % meshSectionCandidate === 0 ? meshSectionCandidate : size;
  const sectionsPerAxis = Math.max(1, Math.floor(size / meshSectionSize));
  const sectionCellCount = meshSectionSize * meshSectionSize * meshSectionSize;
  if (meshSectionSize !== meshSectionCandidate) {
    console.warn("[mesh] section size must divide chunk size; fallback to full chunk", {
      requested: meshSectionCandidate,
      chunkSize: size,
      sectionSize: meshSectionSize,
    });
  }
  console.debug("[spawn] world bounds", {
    worldMinY,
    worldMaxY,
    chunkMinY,
    chunkMaxY,
    size,
  });

  let lightDirty = true;
  const dirtyLightKeys = new Set();

  const fallbackChunk = new Array(size * size * size).fill(0);
  const fallbackSectionLight = new Uint8Array(sectionCellCount);
  fallbackSectionLight.fill(15);
  const deleteMeshBuffers = (buffers) => {
    if (!buffers) return;
    if (buffers.vaoWorld) gl.deleteVertexArray(buffers.vaoWorld);
    if (buffers.vaoLeaf) gl.deleteVertexArray(buffers.vaoLeaf);
    if (buffers.positionBuffer) gl.deleteBuffer(buffers.positionBuffer);
    if (buffers.colorBuffer) gl.deleteBuffer(buffers.colorBuffer);
    if (buffers.normalBuffer) gl.deleteBuffer(buffers.normalBuffer);
    if (buffers.uvBuffer) gl.deleteBuffer(buffers.uvBuffer);
    if (buffers.layerBuffer) gl.deleteBuffer(buffers.layerBuffer);
  };
  const deleteChunkMesh = (mesh) => {
    if (!mesh) return;
    if (mesh.sections instanceof Map) {
      for (const section of mesh.sections.values()) {
        deleteMeshBuffers(section.normal);
        deleteMeshBuffers(section.leaf);
        deleteMeshBuffers(section.translucent);
      }
      mesh.sections.clear();
      return;
    }
    deleteMeshBuffers(mesh.normal);
    deleteMeshBuffers(mesh.leaf);
    deleteMeshBuffers(mesh.translucent);
  };
  const markLightDirty = (key) => {
    lightDirty = true;
    if (typeof key === "string") dirtyLightKeys.add(key);
  };
  const markMeshDirty = (key) => {
    if (typeof key === "string") dirtyMeshKeys.add(key);
  };
  const sectionKeyOf = (chunkKey, sx, sy, sz) => `${chunkKey}|${sx},${sy},${sz}`;
  const parseSectionKey = (value) => {
    if (typeof value !== "string") return null;
    const sep = value.indexOf("|");
    if (sep <= 0) return null;
    const key = value.slice(0, sep);
    const parts = value.slice(sep + 1).split(",");
    if (parts.length !== 3) return null;
    const sx = Number(parts[0]);
    const sy = Number(parts[1]);
    const sz = Number(parts[2]);
    if (!Number.isInteger(sx) || !Number.isInteger(sy) || !Number.isInteger(sz)) {
      return null;
    }
    if (sx < 0 || sy < 0 || sz < 0) return null;
    if (sx >= sectionsPerAxis || sy >= sectionsPerAxis || sz >= sectionsPerAxis) {
      return null;
    }
    return { key, sx, sy, sz };
  };
  const clearDirtySectionsForChunk = (chunkKey) => {
    const prefix = `${chunkKey}|`;
    for (const sectionKey of Array.from(dirtySectionKeys)) {
      if (sectionKey.startsWith(prefix)) {
        dirtySectionKeys.delete(sectionKey);
      }
    }
  };
  const markChunkSectionsDirty = (chunkKey) => {
    if (typeof chunkKey !== "string" || !chunkDatas.has(chunkKey)) return;
    for (let sy = 0; sy < sectionsPerAxis; sy += 1) {
      for (let sz = 0; sz < sectionsPerAxis; sz += 1) {
        for (let sx = 0; sx < sectionsPerAxis; sx += 1) {
          dirtySectionKeys.add(sectionKeyOf(chunkKey, sx, sy, sz));
        }
      }
    }
  };
  const markSectionDirtyByWorld = (wx, wy, wz, touchedChunkKeys) => {
    const cx = Math.floor(wx / size);
    const cy = Math.floor(wy / size);
    const cz = Math.floor(wz / size);
    const key = `${cx},${cy},${cz}`;
    if (!chunkDatas.has(key)) return;
    const lx = wx - cx * size;
    const ly = wy - cy * size;
    const lz = wz - cz * size;
    const sx = Math.floor(lx / meshSectionSize);
    const sy = Math.floor(ly / meshSectionSize);
    const sz = Math.floor(lz / meshSectionSize);
    if (sx < 0 || sy < 0 || sz < 0) return;
    if (sx >= sectionsPerAxis || sy >= sectionsPerAxis || sz >= sectionsPerAxis) return;
    dirtySectionKeys.add(sectionKeyOf(key, sx, sy, sz));
    if (touchedChunkKeys instanceof Set) {
      touchedChunkKeys.add(key);
    }
  };
  const markVoxelAndNeighborSectionsDirty = (wx, wy, wz) => {
    const touched = new Set();
    markSectionDirtyByWorld(wx, wy, wz, touched);
    markSectionDirtyByWorld(wx - 1, wy, wz, touched);
    markSectionDirtyByWorld(wx + 1, wy, wz, touched);
    markSectionDirtyByWorld(wx, wy - 1, wz, touched);
    markSectionDirtyByWorld(wx, wy + 1, wz, touched);
    markSectionDirtyByWorld(wx, wy, wz - 1, touched);
    markSectionDirtyByWorld(wx, wy, wz + 1, touched);
    return touched;
  };
  const markNeighborLightDirty = (key) => {
    const xyz = chunkXyzByKey(key);
    if (!xyz) return;
    const keys = [
      `${xyz.x - 1},${xyz.y},${xyz.z}`,
      `${xyz.x + 1},${xyz.y},${xyz.z}`,
      `${xyz.x},${xyz.y - 1},${xyz.z}`,
      `${xyz.x},${xyz.y + 1},${xyz.z}`,
      `${xyz.x},${xyz.y},${xyz.z - 1}`,
      `${xyz.x},${xyz.y},${xyz.z + 1}`,
    ];
    for (const nkey of keys) {
      if (chunkDatas.has(nkey)) {
        markLightDirty(nkey);
      }
    }
  };
  const rebuildLightMaps = (keys, replaceAll = false) => {
    const entries = buildWorldLight(chunkDatas, size, keys, worldMinY, worldMaxY);
    if (!entries) return;
    if (replaceAll) chunkLights.clear();
    for (const entry of entries) {
      if (!entry) continue;
      const key = entry._0;
      const light = entry._1;
      if (typeof key === "string" && light) {
        chunkLights.set(key, light);
      }
    }
  };
  const expandLightKeys = (keys) => {
    const expanded = new Set();
    for (const key of keys) {
      expanded.add(key);
      const xyz = chunkXyzByKey(key);
      if (!xyz) continue;
      for (let dx = -1; dx <= 1; dx += 1) {
        for (let dy = -1; dy <= 1; dy += 1) {
          for (let dz = -1; dz <= 1; dz += 1) {
            const nkey = `${xyz.x + dx},${xyz.y + dy},${xyz.z + dz}`;
            if (chunkDatas.has(nkey)) {
              expanded.add(nkey);
            }
          }
        }
      }
    }
    return expanded;
  };
  const enqueueChunk = (cx, cy, cz) => {
    const key = `${cx},${cy},${cz}`;
    if (chunkDatas.has(key) || pendingChunks.has(key)) return;
    pendingChunks.add(key);
    chunkQueue.push({ key, cx, cy, cz });
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
    return {
      count: mesh.count,
      vaoWorld: null,
      vaoLeaf: null,
      positionBuffer,
      colorBuffer,
      normalBuffer,
      uvBuffer,
      layerBuffer,
    };
  };
  const getOrCreateChunkMesh = (key, cx, cy, cz) => {
    const prev = chunkMeshes.get(key);
    if (prev && prev.sections instanceof Map) {
      prev.cx = cx;
      prev.cy = cy;
      prev.cz = cz;
      return prev;
    }
    if (prev) {
      deleteChunkMesh(prev);
    }
    const mesh = { cx, cy, cz, sections: new Map() };
    chunkMeshes.set(key, mesh);
    return mesh;
  };
  const buildSectionPaddedData = (baseWorldX, baseWorldY, baseWorldZ) => {
    const pad = meshSectionSize + 2;
    const padded = new Array(pad * pad * pad);
    let idx = 0;
    for (let y = -1; y <= meshSectionSize; y += 1) {
      for (let z = -1; z <= meshSectionSize; z += 1) {
        for (let x = -1; x <= meshSectionSize; x += 1) {
          padded[idx] = getBlockIdAt(
            chunkDatas,
            size,
            baseWorldX + x,
            baseWorldY + y,
            baseWorldZ + z,
          );
          idx += 1;
        }
      }
    }
    return padded;
  };
  const buildSectionLight = (key, sx, sy, sz) => {
    if (useFixedLight) return fallbackSectionLight;
    const chunkLight = chunkLights.get(key);
    if (!chunkLight || typeof chunkLight.length !== "number") {
      return fallbackSectionLight;
    }
    const chunkCellCount = size * size * size;
    if (chunkLight.length < chunkCellCount) {
      return fallbackSectionLight;
    }
    const sectionLight = new Uint8Array(sectionCellCount);
    const offsetX = sx * meshSectionSize;
    const offsetY = sy * meshSectionSize;
    const offsetZ = sz * meshSectionSize;
    let idx = 0;
    for (let y = 0; y < meshSectionSize; y += 1) {
      for (let z = 0; z < meshSectionSize; z += 1) {
        for (let x = 0; x < meshSectionSize; x += 1) {
          const lx = offsetX + x;
          const ly = offsetY + y;
          const lz = offsetZ + z;
          const lightIndex = ((ly * size) + lz) * size + lx;
          sectionLight[idx] = Number(chunkLight[lightIndex] ?? 15);
          idx += 1;
        }
      }
    }
    return sectionLight;
  };
  const buildChunkSectionMesh = (key, cx, cy, cz, sx, sy, sz) => {
    const sectionChunkX = cx * sectionsPerAxis + sx;
    const sectionChunkY = cy * sectionsPerAxis + sy;
    const sectionChunkZ = cz * sectionsPerAxis + sz;
    const baseWorldX = sectionChunkX * meshSectionSize;
    const baseWorldY = sectionChunkY * meshSectionSize;
    const baseWorldZ = sectionChunkZ * meshSectionSize;
    const sectionData = buildSectionPaddedData(baseWorldX, baseWorldY, baseWorldZ);
    const sectionLight = buildSectionLight(key, sx, sy, sz);
    const entries = [{
      x: sectionChunkX,
      y: sectionChunkY,
      z: sectionChunkZ,
      data: sectionData,
      light: sectionLight,
    }];
    const meshPair = window.mcBuildWorldMeshSplit(blockRegistry, entries, meshSectionSize);
    if (!meshPair || !meshPair.normal || !meshPair.leaf || !meshPair.translucent) {
      throw new Error("mcBuildWorldMeshSplit returned invalid data");
    }
    const chunkMesh = getOrCreateChunkMesh(key, cx, cy, cz);
    const id = `${sx},${sy},${sz}`;
    const prevSection = chunkMesh.sections.get(id);
    if (prevSection) {
      deleteMeshBuffers(prevSection.normal);
      deleteMeshBuffers(prevSection.leaf);
      deleteMeshBuffers(prevSection.translucent);
    }
    chunkMesh.sections.set(id, {
      sx,
      sy,
      sz,
      centerX: baseWorldX + meshSectionSize * 0.5,
      centerY: baseWorldY + meshSectionSize * 0.5,
      centerZ: baseWorldZ + meshSectionSize * 0.5,
      normal: toBuffers(meshPair.normal),
      leaf: toBuffers(meshPair.leaf),
      translucent: toBuffers(meshPair.translucent),
    });
  };
  const buildChunkMesh = (key, cx, cy, cz, _data) => {
    for (let sy = 0; sy < sectionsPerAxis; sy += 1) {
      for (let sz = 0; sz < sectionsPerAxis; sz += 1) {
        for (let sx = 0; sx < sectionsPerAxis; sx += 1) {
          buildChunkSectionMesh(key, cx, cy, cz, sx, sy, sz);
        }
      }
    }
  };
  const updateChunkColors = (key) => {
    if (useFixedLight) return { ok: true };
    markChunkSectionsDirty(key);
    return { ok: true };
  };

  const processChunkQueue = () => {
    let remaining = maxGenPerFrame;
    while (remaining > 0 && chunkQueueHead < chunkQueue.length) {
      const next = chunkQueue[chunkQueueHead];
      chunkQueueHead += 1;
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
          markMeshDirty(key);
          markLightDirty(key);
        }
      }
      pendingChunks.delete(key);
      remaining -= 1;
    }
    if (chunkQueueHead >= chunkQueue.length) {
      chunkQueue.length = 0;
      chunkQueueHead = 0;
    } else if (chunkQueueHead > 256 && chunkQueueHead * 2 >= chunkQueue.length) {
      chunkQueue.splice(0, chunkQueueHead);
      chunkQueueHead = 0;
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
  const leafPosition = gl.getAttribLocation(leafProgram, "aPosition");
  const leafColor = gl.getAttribLocation(leafProgram, "aColor");
  const leafUv = gl.getAttribLocation(leafProgram, "aUv");
  const leafLayer = gl.getAttribLocation(leafProgram, "aLayer");
  const leafMvp = gl.getUniformLocation(leafProgram, "uMvp");
  const leafView = gl.getUniformLocation(leafProgram, "uView");
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
  gl.useProgram(leafProgram);
  gl.uniform1i(leafTex, 0);
  gl.uniform1f(leafDebugSolid, window.mcDebugSolid ? 1.0 : 0.0);

  const getBlockId = (wx, wy, wz) => getBlockIdAt(chunkDatas, size, wx, wy, wz);
  const player = createPlayerController({
    canvas,
    worldMinY,
    spawnPosition: spawn.position,
    gameMode: window.mcGameMode,
    chunkMap: chunkDatas,
    chunkSize: size,
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

  const collectDesiredKeys = (cx, cz, renderDistance) => {
    const collectKeys = window.mcCollectRenderChunkKeys;
    if (typeof collectKeys === "function") {
      const keys = collectKeys(cx, cz, renderDistance, chunkMinY, chunkMaxY);
      if (Array.isArray(keys)) return keys;
    }
    const keys = [];
    for (let dx = -renderDistance; dx <= renderDistance; dx += 1) {
      for (let dz = -renderDistance; dz <= renderDistance; dz += 1) {
        for (let cy = chunkMinY; cy <= chunkMaxY; cy += 1) {
          keys.push(`${cx + dx},${cy},${cz + dz}`);
        }
      }
    }
    return keys;
  };

  const rebuildMeshIfNeeded = () => {
    processChunkQueue();
    const cx = Math.floor(player.state.position[0] / size);
    const cz = Math.floor(player.state.position[2] / size);
    const renderDistance = window.mcRenderDistance ?? 2;
    const nextCenterKey = `${cx},0,${cz}`;
    let missing = false;
    const desiredKeys = new Set();
    const keys = collectDesiredKeys(cx, cz, renderDistance);
    for (const key of keys) {
      desiredKeys.add(key);
      if (!chunkDatas.has(key)) {
        const xyz = chunkXyzByKey(key);
        if (xyz) {
          enqueueChunk(xyz.x, xyz.y, xyz.z);
          missing = true;
        }
      }
    }
    if (missing || nextCenterKey !== player.state.centerKey) {
      player.state.centerKey = nextCenterKey;
    }

    // Drop far chunks to cap memory/draw calls.
    for (const key of chunkMeshes.keys()) {
      if (!desiredKeys.has(key)) {
        const mesh = chunkMeshes.get(key);
        if (mesh) deleteChunkMesh(mesh);
        chunkMeshes.delete(key);
        chunkLights.delete(key);
        dirtyMeshKeys.delete(key);
        clearDirtySectionsForChunk(key);
      }
    }
    const removedDataKeys = [];
    for (const key of chunkDatas.keys()) {
      if (!desiredKeys.has(key)) {
        removedDataKeys.push(key);
        chunkDatas.delete(key);
        chunkLights.delete(key);
        dirtyMeshKeys.delete(key);
        clearDirtySectionsForChunk(key);
      }
    }
    for (const key of removedDataKeys) {
      markNeighborLightDirty(key);
    }

    let built = 0;
    for (const key of Array.from(dirtyMeshKeys)) {
      if (built >= maxMeshBuildPerFrame) break;
      if (!desiredKeys.has(key)) {
        dirtyMeshKeys.delete(key);
        continue;
      }
      const data = chunkDatas.get(key);
      if (!data) {
        dirtyMeshKeys.delete(key);
        continue;
      }
      const xyz = chunkXyzByKey(key);
      if (!xyz) {
        dirtyMeshKeys.delete(key);
        continue;
      }
      buildChunkMesh(key, xyz.x, xyz.y, xyz.z, data);
      dirtyMeshKeys.delete(key);
      clearDirtySectionsForChunk(key);
      built += 1;
    }
    for (const sectionKey of Array.from(dirtySectionKeys)) {
      if (built >= maxMeshBuildPerFrame) break;
      const parsed = parseSectionKey(sectionKey);
      if (!parsed) {
        dirtySectionKeys.delete(sectionKey);
        continue;
      }
      if (!desiredKeys.has(parsed.key)) {
        dirtySectionKeys.delete(sectionKey);
        continue;
      }
      if (dirtyMeshKeys.has(parsed.key)) {
        continue;
      }
      if (!chunkDatas.has(parsed.key)) {
        dirtySectionKeys.delete(sectionKey);
        continue;
      }
      const xyz = chunkXyzByKey(parsed.key);
      if (!xyz) {
        dirtySectionKeys.delete(sectionKey);
        continue;
      }
      buildChunkSectionMesh(parsed.key, xyz.x, xyz.y, xyz.z, parsed.sx, parsed.sy, parsed.sz);
      dirtySectionKeys.delete(sectionKey);
      built += 1;
    }
    for (const key of desiredKeys) {
      if (built >= maxMeshBuildPerFrame) break;
      if (chunkMeshes.has(key)) continue;
      const data = chunkDatas.get(key);
      if (!data) continue;
      const xyz = chunkXyzByKey(key);
      if (!xyz) continue;
      buildChunkMesh(key, xyz.x, xyz.y, xyz.z, data);
      clearDirtySectionsForChunk(key);
      built += 1;
    }

    if (lightDirty) {
      if (!useFixedLight) {
        const sourceKeys = dirtyLightKeys.size > 0
          ? Array.from(expandLightKeys(dirtyLightKeys))
          : Array.from(desiredKeys);
        const replaceAll = dirtyLightKeys.size === 0;
        rebuildLightMaps(sourceKeys, replaceAll);
        const updateKeys = dirtyLightKeys.size > 0 ? sourceKeys : Array.from(desiredKeys);
        for (const key of updateKeys) {
          const res = updateChunkColors(key);
          if (!res.ok && res.reason !== "missing-mesh" && res.reason !== "missing-data") {
            console.error("[lighting] failed to update chunk colors", key, res);
          }
        }
      }
      dirtyLightKeys.clear();
      lightDirty = false;
    }
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

  const hotbarItems = padItems(window.mcCollectHotbarItems?.() ?? [], 9);
  reportMissingTextures(hotbarItems, "hotbar");
  if (typeof hotbar.setItems === "function") {
    hotbar.setItems(hotbarItems, textures);
  }

  const inventoryColumns = window.mcInventoryGridX ?? 9;
  const inventoryRows = window.mcInventoryGridY ?? 6;
  const inventoryItems = padItems(
    window.mcCollectInventoryItems?.() ?? [],
    inventoryColumns * inventoryRows,
  );
  let inventoryOpen = false;
  let setInventoryOpen = (open) => {
    inventoryOpen = open;
  };
  reportMissingTextures(inventoryItems, "inventory");
  const inventory = createInventoryUI({
    parent: document.body,
    textures,
    items: inventoryItems,
    columns: inventoryColumns,
    rows: inventoryRows,
    onSelect: (item) => {
      const slotIndex = typeof hotbar.getSelectedIndex === "function"
        ? hotbar.getSelectedIndex()
        : (window.mcHotbarSelectedIndex ?? 0);
      hotbarItems[slotIndex] = item;
      const category = item?.category ?? null;
      if (category == null) {
        console.error("[hotbar] missing category on item", item);
      }
      if (typeof hotbar.setItem === "function") {
        hotbar.setItem(slotIndex, item, textures);
      } else if (typeof hotbar.setItems === "function") {
        hotbar.setItems(hotbarItems, textures);
      }
    },
    onClose: () => {
      setInventoryOpen(false);
    },
    onToggle: () => {
      setInventoryOpen(!inventoryOpen);
    },
    canToggle: () => window.mcGameMode === "creative",
  });
  setInventoryOpen = (open) => {
    inventoryOpen = open;
    window.mcInventoryOpen = open;
    inventory.setOpen(open);
    if (open) {
      if (document.pointerLockElement) document.exitPointerLock();
      crosshair.style.display = "none";
    } else {
      crosshair.style.display = "block";
      canvas.focus();
      canvas.requestPointerLock();
    }
  };
  const markEditedVoxelSections = (wx, wy, wz, keys) => {
    const touched = markVoxelAndNeighborSectionsDirty(wx, wy, wz);
    if (!Array.isArray(keys)) return;
    for (const key of keys) {
      if (!touched.has(key)) {
        markMeshDirty(key);
      }
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
    for (const key of keys) {
      markLightDirty(key);
    }
    return true;
  };

  const raycastBlocks = (origin, dir, maxDist = 10, step = 0.05) => {
    const res = window.mcRaycastBlocks(chunkDatas, size, origin, dir, maxDist, step, mcAirLongId);
    if (!res) return null;
    const block = res.block;
    const prev = res.prev == null ? null : res.prev;
    return { block, prev };
  };

  const updateOutline = (camera) => {
    const hit = raycastBlocks(camera.position, camera.direction);
    if (!hit) return null;
    const currentId = getBlockId(hit.block[0], hit.block[1], hit.block[2]);
    if (!Number.isFinite(currentId)) return null;
    if (currentId === mcAirLongId) return null;
    const decoded = unpackLongId(currentId);
    const renderBlock = typeof window.mcGetRenderBlockByLongId === "function"
      ? window.mcGetRenderBlockByLongId(blockRegistry, currentId)
      : null;
    const block = renderBlock && renderBlock.block ? renderBlock.block : null;
    const isSelectable = block && typeof window.mcBlockIsSelectable === "function"
      ? window.mcBlockIsSelectable(block)
      : currentId !== mcAirLongId;
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
    const hit = raycastBlocks(raycastCamera.position, raycastCamera.direction);
    if (!hit) return;
    if (event.button === 0) {
      const slotIndex = typeof hotbar.getSelectedIndex === "function"
        ? hotbar.getSelectedIndex()
        : (window.mcHotbarSelectedIndex ?? 0);
      const selectedItem = hotbarItems[slotIndex];
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
          for (const key of keys) {
            markLightDirty(key);
          }
        }
      }
    } else if (event.button === 2) {
      if (!hit.prev) return;
      const slotIndex = typeof hotbar.getSelectedIndex === "function"
        ? hotbar.getSelectedIndex()
        : (window.mcHotbarSelectedIndex ?? 0);
      const selectedItem = hotbarItems[slotIndex];
      const category = selectedItem?.category ?? null;
      if (!selectedItem) return;
      if (category == null) {
        console.error("[hotbar] missing category on item", selectedItem);
        return;
      }
      if (category !== "item" && category !== "block") return;
      const useItemOn = window.mcUseItemOn;
      const applyUseOn = window.mcApplyUseOnAction;
      if (typeof useItemOn === "function" && typeof applyUseOn === "function") {
        const action = useItemOn(selectedItem.name, category, hit.block, hit.prev);
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
          for (const key of keys) {
            markLightDirty(key);
          }
        }
      }
    }
  };

  canvas.addEventListener("contextmenu", (event) => event.preventDefault());
  canvas.addEventListener("mousedown", onMouseDown);
  if (hotbar?.host) {
    hotbar.host.addEventListener("hotbarselect", (event) => {
      const _ = event.detail?.index ?? 0;
    });
  }

  const assertCurrentProgram = (label, expected) => {
    if (!enableProgramAssert) return;
    const current = gl.getParameter(gl.CURRENT_PROGRAM);
    if (current !== expected) {
      const name = current === program
        ? "world"
        : current === leafProgram
          ? "leaf"
          : current === outlineProgram
            ? "outline"
            : "unknown";
      throw new Error(`[gl] ${label}: current program mismatch (${name})`);
    }
  };

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
    if (!inventoryOpen) {
      player.update(delta);
    }
    rebuildMeshIfNeeded();

    const eyeHeight = 1.65;
    const camera = cameraFromYawPitch(
      drawCamera,
      player.state.position[0],
      player.state.position[1] + eyeHeight,
      player.state.position[2],
      player.state.yaw,
      player.state.pitch,
    );
    const outlineBlock = updateOutline(camera);
    const aspect = canvasSize.width / canvasSize.height;
    const fov = (window.mcFov ?? 60) * (Math.PI / 180);
    mat4Perspective(projMatrix, fov, aspect, 0.1, 200.0);
    mat4LookAt(viewMatrix, camera.position, camera.center, UP_VECTOR);
    mat4Mul(mvpMatrix, projMatrix, viewMatrix);
    gl.useProgram(program);
    assertCurrentProgram("world mvp", program);
    gl.uniformMatrix4fv(uMvp, false, mvpMatrix);
    gl.uniformMatrix4fv(uView, false, viewMatrix);
    gl.uniform3f(uFogColor, 0.6, 0.8, 1.0);
    const renderDistance = window.mcRenderDistance ?? 0;
    const fogFar = (renderDistance + 0.6) * size;
    const fogNear = fogFar * 0.55;
    gl.uniform1f(uFogNear, fogNear);
    gl.uniform1f(uFogFar, fogFar);

    const maxVisibleDist = (renderDistance + 1.2) * size;
    const maxVisibleDistSq = maxVisibleDist * maxVisibleDist;
    const chunkRadius = meshSectionSize * 0.9;
    const coneCos = Math.cos(Math.min(fov * 0.65, Math.PI * 0.95));
    const visibleMeshes = [];
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
        visibleMeshes.push({ mesh, distSq });
      }
    }

    for (const entry of visibleMeshes) {
      const mesh = entry.mesh;
      const normal = mesh.normal;
      if (normal.count <= 0) continue;
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
    gl.uniformMatrix4fv(leafView, false, viewMatrix);
    gl.uniform3f(leafFogColor, 0.6, 0.8, 1.0);
    gl.uniform1f(leafFogNear, fogNear);
    gl.uniform1f(leafFogFar, fogFar);
    gl.uniform3f(leafTint, leafTintValue[0], leafTintValue[1], leafTintValue[2]);

    for (const entry of visibleMeshes) {
      const mesh = entry.mesh;
      const leaf = mesh.leaf;
      if (leaf.count <= 0) continue;
      const vao = ensureLeafVao(leaf);
      if (!vao) continue;
      gl.bindVertexArray(vao);
      gl.drawArrays(gl.TRIANGLES, 0, leaf.count);
    }
    gl.bindVertexArray(null);

    gl.useProgram(program);
    assertCurrentProgram("translucent mvp", program);

    const translucentMeshes = [];
    for (const entry of visibleMeshes) {
      const mesh = entry.mesh;
      const translucent = mesh.translucent;
      if (!translucent || translucent.count <= 0) continue;
      translucentMeshes.push({ mesh, dist: entry.distSq });
    }
    if (translucentMeshes.length > 0) {
      translucentMeshes.sort((a, b) => b.dist - a.dist);
      gl.enable(gl.BLEND);
      gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
      gl.depthMask(false);
      for (const entry of translucentMeshes) {
        const translucent = entry.mesh.translucent;
        const vao = ensureWorldVao(translucent);
        if (!vao) continue;
        gl.bindVertexArray(vao);
        gl.drawArrays(gl.TRIANGLES, 0, translucent.count);
      }
      gl.bindVertexArray(null);
      gl.depthMask(true);
      gl.disable(gl.BLEND);
    }

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
      `| Loaded: ${chunkDatas.size} ` +
      `| Chunks: ${chunkMeshes.size} ` +
      `| Visible: ${visibleMeshes.length} ` + UPDATE_LABEL;
    requestAnimationFrame(draw);
  }

  draw();
}

export {
  renderTestChunk,
};
