const GLB_MAGIC = 0x46546c67;
const GLB_JSON_CHUNK = 0x4e4f534a;
const GLB_BIN_CHUNK = 0x004e4942;
const GLTF_TRIANGLES = 4;
const DEFAULT_MANIFEST_URL = "./assets/models/entities.json";

const COMPONENTS_PER_TYPE = {
  SCALAR: 1,
  VEC2: 2,
  VEC3: 3,
  VEC4: 4,
};

const COMPONENT_BYTES = {
  5120: 1, // BYTE
  5121: 1, // UBYTE
  5122: 2, // SHORT
  5123: 2, // USHORT
  5125: 4, // UINT
  5126: 4, // FLOAT
};

function mat4Create() {
  const out = new Float32Array(16);
  out[0] = 1;
  out[5] = 1;
  out[10] = 1;
  out[15] = 1;
  return out;
}

function mat4Copy(out, a) {
  out.set(a);
  return out;
}

function mat4Mul(out, a, b) {
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

function mat4FromTRS(out, t, q, s) {
  const x = q[0], y = q[1], z = q[2], w = q[3];
  const x2 = x + x, y2 = y + y, z2 = z + z;
  const xx = x * x2, xy = x * y2, xz = x * z2;
  const yy = y * y2, yz = y * z2, zz = z * z2;
  const wx = w * x2, wy = w * y2, wz = w * z2;
  const sx = s[0], sy = s[1], sz = s[2];
  out[0] = (1 - (yy + zz)) * sx;
  out[1] = (xy + wz) * sx;
  out[2] = (xz - wy) * sx;
  out[3] = 0;
  out[4] = (xy - wz) * sy;
  out[5] = (1 - (xx + zz)) * sy;
  out[6] = (yz + wx) * sy;
  out[7] = 0;
  out[8] = (xz + wy) * sz;
  out[9] = (yz - wx) * sz;
  out[10] = (1 - (xx + yy)) * sz;
  out[11] = 0;
  out[12] = t[0];
  out[13] = t[1];
  out[14] = t[2];
  out[15] = 1;
  return out;
}

function transformPoint(out, m, p) {
  const x = p[0], y = p[1], z = p[2];
  out[0] = m[0] * x + m[4] * y + m[8] * z + m[12];
  out[1] = m[1] * x + m[5] * y + m[9] * z + m[13];
  out[2] = m[2] * x + m[6] * y + m[10] * z + m[14];
  return out;
}

function quatNormalize(out, q) {
  const len = Math.hypot(q[0], q[1], q[2], q[3]);
  if (len <= 0) {
    out[0] = 0; out[1] = 0; out[2] = 0; out[3] = 1;
    return out;
  }
  const inv = 1 / len;
  out[0] = q[0] * inv;
  out[1] = q[1] * inv;
  out[2] = q[2] * inv;
  out[3] = q[3] * inv;
  return out;
}

function quatSlerp(out, a, b, t) {
  let ax = a[0], ay = a[1], az = a[2], aw = a[3];
  let bx = b[0], by = b[1], bz = b[2], bw = b[3];
  let cos = ax * bx + ay * by + az * bz + aw * bw;
  if (cos < 0) {
    cos = -cos;
    bx = -bx; by = -by; bz = -bz; bw = -bw;
  }
  if (cos > 0.9995) {
    out[0] = ax + (bx - ax) * t;
    out[1] = ay + (by - ay) * t;
    out[2] = az + (bz - az) * t;
    out[3] = aw + (bw - aw) * t;
    return quatNormalize(out, out);
  }
  const theta = Math.acos(Math.min(1, Math.max(-1, cos)));
  const sinTheta = Math.sin(theta);
  const w0 = Math.sin((1 - t) * theta) / sinTheta;
  const w1 = Math.sin(t * theta) / sinTheta;
  out[0] = ax * w0 + bx * w1;
  out[1] = ay * w0 + by * w1;
  out[2] = az * w0 + bz * w1;
  out[3] = aw * w0 + bw * w1;
  return out;
}

function createShader(gl, type, source) {
  const shader = gl.createShader(type);
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    const log = gl.getShaderInfoLog(shader);
    gl.deleteShader(shader);
    throw new Error(log || "shader compile failed");
  }
  return shader;
}

function createProgram(gl, vs, fs) {
  const vert = createShader(gl, gl.VERTEX_SHADER, vs);
  const frag = createShader(gl, gl.FRAGMENT_SHADER, fs);
  const program = gl.createProgram();
  gl.attachShader(program, vert);
  gl.attachShader(program, frag);
  gl.linkProgram(program);
  gl.deleteShader(vert);
  gl.deleteShader(frag);
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    const log = gl.getProgramInfoLog(program);
    gl.deleteProgram(program);
    throw new Error(log || "program link failed");
  }
  return program;
}

function decodeDataUri(uri) {
  const comma = uri.indexOf(",");
  if (comma < 0) throw new Error("invalid data uri");
  const data = atob(uri.slice(comma + 1));
  const out = new Uint8Array(data.length);
  for (let i = 0; i < data.length; i += 1) out[i] = data.charCodeAt(i);
  return out.buffer;
}

function parseGlb(buffer) {
  const view = new DataView(buffer);
  if (view.getUint32(0, true) !== GLB_MAGIC) throw new Error("invalid glb magic");
  const version = view.getUint32(4, true);
  if (version !== 2) throw new Error(`unsupported glb version: ${version}`);
  const totalLength = view.getUint32(8, true);
  let offset = 12;
  let jsonChunk = null;
  let binChunk = null;
  while (offset + 8 <= totalLength) {
    const len = view.getUint32(offset, true);
    const type = view.getUint32(offset + 4, true);
    offset += 8;
    const end = offset + len;
    if (end > view.byteLength) break;
    const chunk = buffer.slice(offset, end);
    if (type === GLB_JSON_CHUNK) jsonChunk = chunk;
    if (type === GLB_BIN_CHUNK) binChunk = chunk;
    offset = end;
  }
  if (!jsonChunk) throw new Error("missing GLB JSON chunk");
  return { gltf: JSON.parse(new TextDecoder("utf-8").decode(jsonChunk)), binChunk };
}

async function loadGltfPayload(url) {
  const absUrl = new URL(url, window.location.href).href;
  if (absUrl.toLowerCase().endsWith(".glb")) {
    const res = await fetch(absUrl);
    if (!res.ok) throw new Error(`failed to fetch glb: ${absUrl}`);
    const parsed = parseGlb(await res.arrayBuffer());
    return { url: absUrl, baseUrl: absUrl, gltf: parsed.gltf, glbBin: parsed.binChunk };
  }
  const res = await fetch(absUrl);
  if (!res.ok) throw new Error(`failed to fetch gltf: ${absUrl}`);
  return { url: absUrl, baseUrl: absUrl, gltf: await res.json(), glbBin: null };
}

function resolveUrl(baseUrl, uri) {
  return new URL(uri, baseUrl).href;
}

async function loadBuffers(gltf, baseUrl, glbBin) {
  const defs = gltf.buffers ?? [];
  const out = new Array(defs.length);
  for (let i = 0; i < defs.length; i += 1) {
    const def = defs[i] ?? {};
    if (typeof def.uri === "string" && def.uri.length > 0) {
      if (def.uri.startsWith("data:")) {
        out[i] = decodeDataUri(def.uri);
      } else {
        const res = await fetch(resolveUrl(baseUrl, def.uri));
        if (!res.ok) throw new Error(`failed to fetch buffer: ${def.uri}`);
        out[i] = await res.arrayBuffer();
      }
    } else if (i === 0 && glbBin) {
      out[i] = glbBin;
    } else {
      throw new Error(`missing buffer payload at index ${i}`);
    }
  }
  return out;
}

function readAccessor(gltf, buffers, accessorIndex, expectedComps = null) {
  const accessor = (gltf.accessors ?? [])[accessorIndex];
  if (!accessor) throw new Error(`missing accessor ${accessorIndex}`);
  if (accessor.sparse) throw new Error("sparse accessors are not supported");
  const comps = COMPONENTS_PER_TYPE[accessor.type];
  if (!comps) throw new Error(`unsupported accessor type ${accessor.type}`);
  if (expectedComps != null && comps !== expectedComps) {
    throw new Error(`accessor component mismatch at ${accessorIndex}`);
  }
  const compBytes = COMPONENT_BYTES[accessor.componentType];
  if (!compBytes) throw new Error(`unsupported component type ${accessor.componentType}`);
  const viewDef = (gltf.bufferViews ?? [])[accessor.bufferView];
  if (!viewDef) throw new Error(`missing bufferView for accessor ${accessorIndex}`);
  const buffer = buffers[viewDef.buffer];
  if (!buffer) throw new Error(`missing buffer payload ${viewDef.buffer}`);
  const count = accessor.count ?? 0;
  const stride = viewDef.byteStride ?? (compBytes * comps);
  const byteOffset = (viewDef.byteOffset ?? 0) + (accessor.byteOffset ?? 0);
  const view = new DataView(buffer, byteOffset, stride * count);
  const out = new Float32Array(count * comps);
  let ptr = 0;
  for (let i = 0; i < count; i += 1) {
    const base = i * stride;
    for (let c = 0; c < comps; c += 1) {
      const off = base + c * compBytes;
      let raw = 0;
      if (accessor.componentType === 5120) raw = view.getInt8(off);
      else if (accessor.componentType === 5121) raw = view.getUint8(off);
      else if (accessor.componentType === 5122) raw = view.getInt16(off, true);
      else if (accessor.componentType === 5123) raw = view.getUint16(off, true);
      else if (accessor.componentType === 5125) raw = view.getUint32(off, true);
      else raw = view.getFloat32(off, true);
      out[ptr] = raw;
      ptr += 1;
    }
  }
  return { accessor, values: out };
}

function readIndices(gltf, buffers, accessorIndex) {
  const { accessor, values } = readAccessor(gltf, buffers, accessorIndex, 1);
  if (accessor.componentType === 5125) {
    const out = new Uint32Array(values.length);
    for (let i = 0; i < values.length; i += 1) out[i] = values[i];
    return out;
  }
  const out = new Uint16Array(values.length);
  for (let i = 0; i < values.length; i += 1) out[i] = values[i];
  return out;
}

function createWhiteTexture(gl) {
  const tex = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, tex);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
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
  gl.bindTexture(gl.TEXTURE_2D, null);
  return tex;
}

async function loadImage(url) {
  const img = new Image();
  img.decoding = "async";
  await new Promise((resolve, reject) => {
    img.onload = () => resolve();
    img.onerror = reject;
    img.src = url;
  });
  return img;
}

async function loadImageFromBuffer(buffer, mimeType = "image/png") {
  const blob = new Blob([buffer], { type: mimeType });
  const url = URL.createObjectURL(blob);
  try {
    return await loadImage(url);
  } finally {
    URL.revokeObjectURL(url);
  }
}

function isMipFilter(filter) {
  return filter === 9984 || filter === 9985 || filter === 9986 || filter === 9987;
}

function normalizeSampler(gl, samplerDef) {
  const out = {
    minFilter: gl.NEAREST,
    magFilter: gl.NEAREST,
    wrapS: gl.CLAMP_TO_EDGE,
    wrapT: gl.CLAMP_TO_EDGE,
  };
  if (!samplerDef || typeof samplerDef !== "object") return out;
  const min = Number(samplerDef.minFilter);
  const mag = Number(samplerDef.magFilter);
  const wrapS = Number(samplerDef.wrapS);
  const wrapT = Number(samplerDef.wrapT);
  if (Number.isInteger(min) && (min === 9728 || min === 9729 || isMipFilter(min))) {
    out.minFilter = min;
  }
  if (Number.isInteger(mag) && (mag === 9728 || mag === 9729)) {
    out.magFilter = mag;
  }
  if (Number.isInteger(wrapS) && (wrapS === 33071 || wrapS === 33648 || wrapS === 10497)) {
    out.wrapS = wrapS;
  }
  if (Number.isInteger(wrapT) && (wrapT === 33071 || wrapT === 33648 || wrapT === 10497)) {
    out.wrapT = wrapT;
  }
  return out;
}

function createTextureFromImage(gl, img, samplerDef = null) {
  const sampler = normalizeSampler(gl, samplerDef);
  const tex = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, tex);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, sampler.minFilter);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, sampler.magFilter);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, sampler.wrapS);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, sampler.wrapT);
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, img);
  if (isMipFilter(sampler.minFilter)) {
    gl.generateMipmap(gl.TEXTURE_2D);
  }
  gl.bindTexture(gl.TEXTURE_2D, null);
  return tex;
}

async function loadTextures(gl, gltf, buffers, baseUrl, whiteTexture) {
  const imageDefs = gltf.images ?? [];
  const images = new Array(imageDefs.length);
  for (let i = 0; i < imageDefs.length; i += 1) {
    const def = imageDefs[i] ?? {};
    if (typeof def.uri === "string" && def.uri.length > 0) {
      if (def.uri.startsWith("data:")) {
        images[i] = await loadImageFromBuffer(
          decodeDataUri(def.uri),
          def.mimeType || "image/png",
        );
      } else {
        images[i] = await loadImage(resolveUrl(baseUrl, def.uri));
      }
      continue;
    }
    if (Number.isInteger(def.bufferView)) {
      const view = (gltf.bufferViews ?? [])[def.bufferView];
      if (!view) continue;
      const src = buffers[view.buffer];
      if (!src) continue;
      const offset = view.byteOffset ?? 0;
      const length = view.byteLength ?? 0;
      if (length > 0) {
        images[i] = await loadImageFromBuffer(
          src.slice(offset, offset + length),
          def.mimeType || "image/png",
        );
      }
    }
  }
  const texDefs = gltf.textures ?? [];
  const samplerDefs = gltf.samplers ?? [];
  const textures = new Array(texDefs.length);
  for (let i = 0; i < texDefs.length; i += 1) {
    const def = texDefs[i] ?? {};
    const srcIndex = Number.isInteger(def.source) ? def.source : -1;
    const img = srcIndex >= 0 && srcIndex < images.length ? images[srcIndex] : null;
    const sampler = Number.isInteger(def.sampler) ? samplerDefs[def.sampler] : null;
    textures[i] = img ? createTextureFromImage(gl, img, sampler) : whiteTexture;
  }
  return textures;
}

function buildMaterials(gltf, textures, whiteTexture) {
  const defs = gltf.materials ?? [];
  if (defs.length === 0) {
    return [{
      name: null,
      texture: whiteTexture,
      hasTexture: false,
      factor: [1, 1, 1, 1],
      alphaMode: "OPAQUE",
      alphaCutoff: 0.5,
      doubleSided: false,
    }];
  }
  return defs.map((def) => {
    const pbr = def?.pbrMetallicRoughness ?? {};
    const texIndex = Number.isInteger(pbr.baseColorTexture?.index) ? pbr.baseColorTexture.index : -1;
    const factor = Array.isArray(pbr.baseColorFactor) && pbr.baseColorFactor.length >= 4
      ? [Number(pbr.baseColorFactor[0]) || 1, Number(pbr.baseColorFactor[1]) || 1, Number(pbr.baseColorFactor[2]) || 1, Number(pbr.baseColorFactor[3]) || 1]
      : [1, 1, 1, 1];
    const tex = texIndex >= 0 && texIndex < textures.length ? textures[texIndex] : whiteTexture;
    return {
      name: typeof def?.name === "string" && def.name.length > 0 ? def.name : null,
      texture: tex ?? whiteTexture,
      hasTexture: texIndex >= 0 && tex !== whiteTexture,
      factor,
      alphaMode: typeof def?.alphaMode === "string" ? def.alphaMode : "OPAQUE",
      alphaCutoff: Number.isFinite(Number(def?.alphaCutoff)) ? Number(def.alphaCutoff) : 0.5,
      doubleSided: def?.doubleSided === true,
    };
  });
}

function sampleAnimKey(times, t) {
  if (times.length <= 1) return 0;
  if (t <= times[0]) return 0;
  const last = times.length - 1;
  if (t >= times[last]) return last - 1;
  let lo = 0, hi = last;
  while (lo + 1 < hi) {
    const mid = (lo + hi) >> 1;
    if (times[mid] <= t) lo = mid;
    else hi = mid;
  }
  return lo;
}

function buildAnimations(gltf, buffers) {
  const defs = gltf.animations ?? [];
  return defs.map((def, i) => {
    const samplers = def.samplers ?? [];
    const channels = def.channels ?? [];
    const outChannels = [];
    let duration = 0;
    for (let c = 0; c < channels.length; c += 1) {
      const channel = channels[c] ?? {};
      const sampler = samplers[channel.sampler];
      if (!sampler) continue;
      const node = channel.target?.node;
      const rawPath = channel.target?.path;
      const path = rawPath === "position" ? "translation" : rawPath;
      if (!Number.isInteger(node)) continue;
      if (path !== "translation" && path !== "rotation" && path !== "scale") continue;
      const input = readAccessor(gltf, buffers, sampler.input, 1).values;
      const comps = path === "rotation" ? 4 : 3;
      const outputRaw = readAccessor(gltf, buffers, sampler.output, comps).values;
      if (input.length === 0) continue;
      const interpolationRaw = typeof sampler.interpolation === "string"
        ? sampler.interpolation
        : "LINEAR";
      let interpolation = interpolationRaw;
      let output = outputRaw;
      if (interpolationRaw === "CUBICSPLINE") {
        const keyCount = input.length;
        const packed = keyCount * comps * 3;
        if (outputRaw.length >= packed) {
          const reduced = new Float32Array(keyCount * comps);
          for (let k = 0; k < keyCount; k += 1) {
            const src = (k * 3 + 1) * comps;
            const dst = k * comps;
            for (let c2 = 0; c2 < comps; c2 += 1) {
              reduced[dst + c2] = outputRaw[src + c2];
            }
          }
          output = reduced;
          // Blockbench tracks export as cubic in some cases; for now we
          // conservatively evaluate by linearly blending value keys.
          interpolation = "LINEAR";
        } else {
          interpolation = "LINEAR";
        }
      }
      duration = Math.max(duration, Number(input[input.length - 1]) || 0);
      outChannels.push({
        node,
        path,
        interpolation,
        input,
        output,
      });
    }
    return { name: typeof def.name === "string" ? def.name : `animation_${i}`, duration, channels: outChannels };
  });
}

function createProgramInfo(gl) {
  const vs = `#version 300 es
    precision highp float;
    in vec3 aPosition;
    in vec3 aNormal;
    in vec2 aUv;
    uniform mat4 uModel;
    uniform mat4 uView;
    uniform mat4 uViewProj;
    out vec3 vNormal;
    out vec2 vUv;
    out float vFogDist;
    void main() {
      vec4 world = uModel * vec4(aPosition, 1.0);
      vNormal = mat3(uModel) * aNormal;
      vUv = aUv;
      vFogDist = length((uView * world).xyz);
      gl_Position = uViewProj * world;
    }
  `;
  const fs = `#version 300 es
    precision highp float;
    in vec3 vNormal;
    in vec2 vUv;
    in float vFogDist;
    uniform sampler2D uTex;
    uniform bool uHasTexture;
    uniform vec4 uColor;
    uniform bool uAlphaMask;
    uniform float uAlphaCutoff;
    uniform vec3 uFogColor;
    uniform float uFogNear;
    uniform float uFogFar;
    out vec4 outColor;
    void main() {
      vec4 tex = uHasTexture ? texture(uTex, vUv) : vec4(1.0);
      vec4 base = tex * uColor;
      if (uAlphaMask && base.a < uAlphaCutoff) discard;
      if (base.a <= 0.001) discard;
      vec3 lightDir = normalize(vec3(0.35, 0.75, 0.25));
      float lit = max(dot(normalize(vNormal), lightDir), 0.0) * 0.6 + 0.4;
      float fog = smoothstep(uFogNear, uFogFar, vFogDist);
      outColor = vec4(mix(base.rgb * lit, uFogColor, fog), base.a);
    }
  `;
  const program = createProgram(gl, vs, fs);
  return {
    program,
    aPosition: gl.getAttribLocation(program, "aPosition"),
    aNormal: gl.getAttribLocation(program, "aNormal"),
    aUv: gl.getAttribLocation(program, "aUv"),
    uModel: gl.getUniformLocation(program, "uModel"),
    uView: gl.getUniformLocation(program, "uView"),
    uViewProj: gl.getUniformLocation(program, "uViewProj"),
    uTex: gl.getUniformLocation(program, "uTex"),
    uHasTexture: gl.getUniformLocation(program, "uHasTexture"),
    uColor: gl.getUniformLocation(program, "uColor"),
    uAlphaMask: gl.getUniformLocation(program, "uAlphaMask"),
    uAlphaCutoff: gl.getUniformLocation(program, "uAlphaCutoff"),
    uFogColor: gl.getUniformLocation(program, "uFogColor"),
    uFogNear: gl.getUniformLocation(program, "uFogNear"),
    uFogFar: gl.getUniformLocation(program, "uFogFar"),
  };
}

async function loadEntityConfigs({ direct = null, manifestUrl = DEFAULT_MANIFEST_URL } = {}) {
  if (Array.isArray(direct)) return direct;
  if (!manifestUrl) return [];
  try {
    const res = await fetch(manifestUrl, { cache: "no-store" });
    if (!res.ok) return [];
    const payload = await res.json();
    if (Array.isArray(payload)) return payload;
    if (payload && Array.isArray(payload.entities)) {
      return payload.entities;
    }
    return [];
  } catch {
    return [];
  }
}

function createGltfEntityRenderer(gl) {
  const info = createProgramInfo(gl);
  const whiteTexture = createWhiteTexture(gl);
  const assets = new Map();
  const externalTextures = new Map();
  const instances = [];
  const tmp = { modelNode: mat4Create(), worldPos: [0, 0, 0] };

  const loadExternalTexture = async (url) => {
    if (typeof url !== "string" || url.length === 0) return null;
    const abs = new URL(url, window.location.href).href;
    const cached = externalTextures.get(abs);
    if (cached) return cached;
    const promise = (async () => {
      const image = await loadImage(abs);
      return createTextureFromImage(gl, image);
    })();
    externalTextures.set(abs, promise);
    try {
      const tex = await promise;
      externalTextures.set(abs, tex);
      return tex;
    } catch (err) {
      externalTextures.delete(abs);
      throw err;
    }
  };

  const loadAsset = async (url) => {
    const key = new URL(url, window.location.href).href;
    const cached = assets.get(key);
    if (cached) return cached;
    const promise = (async () => {
      const payload = await loadGltfPayload(key);
      const gltf = payload.gltf;
      const buffers = await loadBuffers(gltf, payload.baseUrl, payload.glbBin);
      const textures = await loadTextures(
        gl,
        gltf,
        buffers,
        payload.baseUrl,
        whiteTexture,
      );
      const materials = buildMaterials(gltf, textures, whiteTexture);
      const animations = buildAnimations(gltf, buffers);
      const nodeDefs = gltf.nodes ?? [];
      const nodes = nodeDefs.map((n) => ({
        mesh: Number.isInteger(n?.mesh) ? n.mesh : -1,
        children: Array.isArray(n?.children) ? n.children.filter((v) => Number.isInteger(v)) : [],
        t: Array.isArray(n?.translation) ? [Number(n.translation[0]) || 0, Number(n.translation[1]) || 0, Number(n.translation[2]) || 0] : [0, 0, 0],
        r: Array.isArray(n?.rotation) ? quatNormalize([0, 0, 0, 1], [Number(n.rotation[0]) || 0, Number(n.rotation[1]) || 0, Number(n.rotation[2]) || 0, Number(n.rotation[3]) || 1]) : [0, 0, 0, 1],
        s: Array.isArray(n?.scale) ? [Number(n.scale[0]) || 1, Number(n.scale[1]) || 1, Number(n.scale[2]) || 1] : [1, 1, 1],
        matrix: Array.isArray(n?.matrix) && n.matrix.length === 16
          ? Float32Array.from(n.matrix.map((v) => Number(v) || 0))
          : null,
      }));
      const scene = (gltf.scenes ?? [])[Number.isInteger(gltf.scene) ? gltf.scene : 0];
      const roots = Array.isArray(scene?.nodes)
        ? scene.nodes.filter((v) => Number.isInteger(v))
        : nodes.map((_, i) => i);
      const meshes = (gltf.meshes ?? []).map((mesh) => {
        const primitives = [];
        for (const prim of mesh?.primitives ?? []) {
          const mode = Number.isFinite(Number(prim.mode)) ? Number(prim.mode) : GLTF_TRIANGLES;
          if (mode !== GLTF_TRIANGLES) continue;
          const attrs = prim.attributes ?? {};
          if (!Number.isInteger(attrs.POSITION)) continue;
          const pos = readAccessor(gltf, buffers, attrs.POSITION, 3).values;
          const vertexCount = Math.floor(pos.length / 3);
          if (vertexCount <= 0) continue;
          const normal = Number.isInteger(attrs.NORMAL) ? readAccessor(gltf, buffers, attrs.NORMAL, 3).values : null;
          const uv0 = Number.isInteger(attrs.TEXCOORD_0) ? readAccessor(gltf, buffers, attrs.TEXCOORD_0, 2).values : null;
          const normals = new Float32Array(vertexCount * 3);
          if (normal && normal.length === normals.length) normals.set(normal);
          else for (let i = 0; i < vertexCount; i += 1) normals[i * 3 + 1] = 1;
          const uvs = new Float32Array(vertexCount * 2);
          if (uv0 && uv0.length === uvs.length) uvs.set(uv0);
          const vao = gl.createVertexArray();
          gl.bindVertexArray(vao);
          const posBuf = gl.createBuffer();
          gl.bindBuffer(gl.ARRAY_BUFFER, posBuf);
          gl.bufferData(gl.ARRAY_BUFFER, pos, gl.STATIC_DRAW);
          gl.enableVertexAttribArray(info.aPosition);
          gl.vertexAttribPointer(info.aPosition, 3, gl.FLOAT, false, 0, 0);
          const nBuf = gl.createBuffer();
          gl.bindBuffer(gl.ARRAY_BUFFER, nBuf);
          gl.bufferData(gl.ARRAY_BUFFER, normals, gl.STATIC_DRAW);
          gl.enableVertexAttribArray(info.aNormal);
          gl.vertexAttribPointer(info.aNormal, 3, gl.FLOAT, false, 0, 0);
          const uvBuf = gl.createBuffer();
          gl.bindBuffer(gl.ARRAY_BUFFER, uvBuf);
          gl.bufferData(gl.ARRAY_BUFFER, uvs, gl.STATIC_DRAW);
          gl.enableVertexAttribArray(info.aUv);
          gl.vertexAttribPointer(info.aUv, 2, gl.FLOAT, false, 0, 0);
          let indexBuf = null;
          let indexType = null;
          let count = vertexCount;
          if (Number.isInteger(prim.indices)) {
            const idx = readIndices(gltf, buffers, prim.indices);
            indexBuf = gl.createBuffer();
            gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuf);
            gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, idx, gl.STATIC_DRAW);
            indexType = idx instanceof Uint32Array ? gl.UNSIGNED_INT : gl.UNSIGNED_SHORT;
            count = idx.length;
          }
          gl.bindVertexArray(null);
          let cx = 0, cy = 0, cz = 0;
          for (let i = 0; i < vertexCount; i += 1) {
            cx += pos[i * 3];
            cy += pos[i * 3 + 1];
            cz += pos[i * 3 + 2];
          }
          primitives.push({
            vao,
            posBuf,
            nBuf,
            uvBuf,
            indexBuf,
            indexType,
            count,
            materialIndex: Number.isInteger(prim.material) ? prim.material : 0,
            center: [cx / vertexCount, cy / vertexCount, cz / vertexCount],
          });
        }
        return { primitives };
      });
      return {
        url: payload.url,
        nodes,
        meshes,
        roots,
        materials,
        textures,
        animations,
      };
    })();
    assets.set(key, promise);
    const asset = await promise;
    assets.set(key, asset);
    return asset;
  };

  const loadFromConfigs = async (configs) => {
    instances.length = 0;
    if (!Array.isArray(configs)) return;
    const seenIds = new Set();
    for (const cfg of configs) {
      if (typeof cfg?.url !== "string" || cfg.url.length === 0) continue;
      const asset = await loadAsset(cfg.url);
      const instanceId = typeof cfg.id === "string" && cfg.id.length > 0
        ? cfg.id
        : String(instances.length);
      if (seenIds.has(instanceId)) {
        console.warn("[gltf] duplicate entity id; runtime API may target first match only", instanceId, cfg.url);
      }
      seenIds.add(instanceId);
      const textureOverridesByIndex = new Map();
      const textureOverridesByName = new Map();
      const knownMaterialNames = new Set(
        (asset.materials ?? [])
          .map((m) => m?.name)
          .filter((name) => typeof name === "string" && name.length > 0),
      );
      let defaultTextureOverride = null;
      if (typeof cfg.texture === "string" && cfg.texture.length > 0) {
        try {
          const tex = await loadExternalTexture(cfg.texture);
          if (tex) defaultTextureOverride = tex;
        } catch (err) {
          console.warn("[gltf] failed to load entity texture override", cfg.texture, err);
        }
      }
      if (Array.isArray(cfg.textures)) {
        for (let i = 0; i < cfg.textures.length; i += 1) {
          const url = cfg.textures[i];
          if (typeof url !== "string" || url.length === 0) continue;
          try {
            const tex = await loadExternalTexture(url);
            if (tex) textureOverridesByIndex.set(i, tex);
          } catch (err) {
            console.warn("[gltf] failed to load material texture override", i, url, err);
          }
        }
      } else if (cfg.textures && typeof cfg.textures === "object") {
        for (const [key, url] of Object.entries(cfg.textures)) {
          if (typeof url !== "string" || url.length === 0) continue;
          const index = Number.parseInt(key, 10);
          if (Number.isInteger(index) && String(index) === key) {
            try {
              const tex = await loadExternalTexture(url);
              if (tex) textureOverridesByIndex.set(index, tex);
            } catch (err) {
              console.warn("[gltf] failed to load material texture override", index, url, err);
            }
            continue;
          }
          try {
            const tex = await loadExternalTexture(url);
            if (tex) textureOverridesByName.set(key, tex);
            if (!knownMaterialNames.has(key)) {
              console.warn("[gltf] unknown material name in textures override", key, cfg.url);
            }
          } catch (err) {
            console.warn("[gltf] failed to load named material texture override", key, url, err);
          }
        }
      }
      if (cfg.materialTextures && typeof cfg.materialTextures === "object") {
        for (const [name, url] of Object.entries(cfg.materialTextures)) {
          if (typeof url !== "string" || url.length === 0) continue;
          try {
            const tex = await loadExternalTexture(url);
            if (tex) textureOverridesByName.set(name, tex);
            if (!knownMaterialNames.has(name)) {
              console.warn("[gltf] unknown material name in materialTextures override", name, cfg.url);
            }
          } catch (err) {
            console.warn("[gltf] failed to load named material texture override", name, url, err);
          }
        }
      }
      if (
        !defaultTextureOverride &&
        textureOverridesByIndex.size === 0 &&
        textureOverridesByName.size === 0 &&
        Array.isArray(asset.materials) &&
        asset.materials.every((m) => !m.hasTexture)
      ) {
        console.warn(
          "[gltf] model has no embedded texture; specify `texture`, `textures`, or `materialTextures` in entity config",
          cfg.url,
        );
        continue;
      }
      const nodeLocal = asset.nodes.map(() => mat4Create());
      const nodeWorld = asset.nodes.map(() => mat4Create());
      const model = mat4Create();
      const pos = Array.isArray(cfg.position) ? [Number(cfg.position[0]) || 0, Number(cfg.position[1]) || 0, Number(cfg.position[2]) || 0] : [0, 0, 0];
      const rot = Array.isArray(cfg.rotation) ? quatNormalize([0, 0, 0, 1], [Number(cfg.rotation[0]) || 0, Number(cfg.rotation[1]) || 0, Number(cfg.rotation[2]) || 0, Number(cfg.rotation[3]) || 1]) : [0, 0, 0, 1];
      const sc = Array.isArray(cfg.scale) ? [Number(cfg.scale[0]) || 1, Number(cfg.scale[1]) || 1, Number(cfg.scale[2]) || 1] : [1, 1, 1];
      mat4FromTRS(model, pos, rot, sc);
      let animIndex = -1;
      if (cfg.animation === false || cfg.animation === "none") {
        animIndex = -1;
      } else if (typeof cfg.animation === "string") {
        const found = asset.animations.findIndex((v) => v.name === cfg.animation);
        if (found >= 0) {
          animIndex = found;
        } else if (asset.animations.length > 0) {
          animIndex = 0;
          console.warn(
            "[gltf] animation not found; fallback to first animation",
            cfg.animation,
            "->",
            asset.animations[0]?.name ?? "unnamed",
            cfg.url,
          );
        }
      } else if (Number.isInteger(cfg.animation)) {
        if (cfg.animation >= 0 && cfg.animation < asset.animations.length) {
          animIndex = cfg.animation;
        } else if (asset.animations.length > 0) {
          animIndex = 0;
          console.warn(
            "[gltf] animation index out of range; fallback to first animation",
            cfg.animation,
            cfg.url,
          );
        }
      } else if (asset.animations.length > 0) {
        animIndex = 0;
      }
      instances.push({
        id: instanceId,
        asset,
        config: cfg,
        nodeLocal,
        nodeWorld,
        model,
        animIndex,
        animTime: Number.isFinite(Number(cfg.startTime)) ? Number(cfg.startTime) : 0,
        animSpeed: Number.isFinite(Number(cfg.speed)) ? Number(cfg.speed) : 1,
        loop: (cfg.loop ?? cfg.looped) !== false,
        defaultTextureOverride,
        textureOverridesByIndex,
        textureOverridesByName,
      });
    }
  };

  const getInstanceById = (entityId) => {
    if (instances.length === 0) return null;
    if (typeof entityId === "string" && entityId.length > 0) {
      const byId = instances.find((inst) => inst.id === entityId);
      if (byId) return byId;
      if (/^\d+$/.test(entityId)) {
        const index = Number.parseInt(entityId, 10);
        if (index >= 0 && index < instances.length) return instances[index];
      }
      return null;
    }
    if (Number.isInteger(entityId) && entityId >= 0 && entityId < instances.length) {
      return instances[entityId];
    }
    return null;
  };

  const setAnimation = (entityId, clip) => {
    const inst = getInstanceById(entityId);
    if (!inst) {
      console.warn("[gltf] setAnimation: entity not found", entityId);
      return false;
    }
    let next = -1;
    if (clip === false || clip === null || clip === undefined || clip === "none") {
      next = -1;
    } else if (typeof clip === "string") {
      next = inst.asset.animations.findIndex((v) => v.name === clip);
      if (next < 0) {
        console.warn("[gltf] setAnimation: clip not found", clip, "entity:", inst.id);
        return false;
      }
    } else if (Number.isInteger(clip)) {
      if (clip >= 0 && clip < inst.asset.animations.length) {
        next = clip;
      } else {
        console.warn("[gltf] setAnimation: clip index out of range", clip, "entity:", inst.id);
        return false;
      }
    } else {
      console.warn("[gltf] setAnimation: invalid clip type", clip, "entity:", inst.id);
      return false;
    }
    inst.animIndex = next;
    inst.animTime = 0;
    return true;
  };

  const setTexture = async (entityId, path) => {
    const inst = getInstanceById(entityId);
    if (!inst) {
      console.warn("[gltf] setTexture: entity not found", entityId);
      return false;
    }
    if (path === false || path === null || path === undefined || path === "none") {
      inst.defaultTextureOverride = null;
      inst.textureOverridesByIndex.clear();
      inst.textureOverridesByName.clear();
      return true;
    }
    if (typeof path !== "string" || path.length === 0) {
      console.warn("[gltf] setTexture: invalid path", path, "entity:", inst.id);
      return false;
    }
    try {
      const tex = await loadExternalTexture(path);
      if (!tex) return false;
      inst.defaultTextureOverride = tex;
      inst.textureOverridesByIndex.clear();
      inst.textureOverridesByName.clear();
      inst.config.texture = path;
      return true;
    } catch (err) {
      console.warn("[gltf] setTexture: failed to load texture", path, "entity:", inst.id, err);
      return false;
    }
  };

  const getEntityIds = () => instances.map((inst, index) => inst.id ?? String(index));

  const update = (deltaSeconds) => {
    for (const inst of instances) {
      const nodes = inst.asset.nodes;
      const anim = inst.animIndex >= 0 ? inst.asset.animations[inst.animIndex] : null;
      const localT = nodes.map((n) => [n.t[0], n.t[1], n.t[2]]);
      const localR = nodes.map((n) => [n.r[0], n.r[1], n.r[2], n.r[3]]);
      const localS = nodes.map((n) => [n.s[0], n.s[1], n.s[2]]);
      const matrixNodes = nodes.map((n) => n.matrix instanceof Float32Array);
      if (anim && anim.channels.length > 0) {
        const duration = anim.duration > 0 ? anim.duration : 0;
        inst.animTime += deltaSeconds * inst.animSpeed;
        if (duration > 0) {
          if (inst.loop) inst.animTime = ((inst.animTime % duration) + duration) % duration;
          else inst.animTime = Math.max(0, Math.min(duration, inst.animTime));
        } else {
          inst.animTime = 0;
        }
        const t = duration > 0 ? inst.animTime : 0;
        for (const ch of anim.channels) {
          if (matrixNodes[ch.node]) continue;
          const k = sampleAnimKey(ch.input, t);
          const t0 = ch.input[k];
          const t1 = ch.input[Math.min(k + 1, ch.input.length - 1)];
          const f = t1 > t0 ? (t - t0) / (t1 - t0) : 0;
          if (ch.path === "rotation") {
            const i0 = k * 4, i1 = Math.min(k + 1, ch.input.length - 1) * 4;
            const qa = [ch.output[i0], ch.output[i0 + 1], ch.output[i0 + 2], ch.output[i0 + 3]];
            const qb = [ch.output[i1], ch.output[i1 + 1], ch.output[i1 + 2], ch.output[i1 + 3]];
            quatSlerp(localR[ch.node], qa, qb, ch.interpolation === "STEP" ? 0 : f);
          } else {
            const mul = 3;
            const i0 = k * mul, i1 = Math.min(k + 1, ch.input.length - 1) * mul;
            const dst = ch.path === "translation" ? localT[ch.node] : localS[ch.node];
            if (ch.interpolation === "STEP") {
              dst[0] = ch.output[i0];
              dst[1] = ch.output[i0 + 1];
              dst[2] = ch.output[i0 + 2];
            } else {
              dst[0] = ch.output[i0] + (ch.output[i1] - ch.output[i0]) * f;
              dst[1] = ch.output[i0 + 1] + (ch.output[i1 + 1] - ch.output[i0 + 1]) * f;
              dst[2] = ch.output[i0 + 2] + (ch.output[i1 + 2] - ch.output[i0 + 2]) * f;
            }
          }
        }
      }
      for (let i = 0; i < nodes.length; i += 1) {
        if (matrixNodes[i]) {
          mat4Copy(inst.nodeLocal[i], nodes[i].matrix);
        } else {
          mat4FromTRS(inst.nodeLocal[i], localT[i], localR[i], localS[i]);
        }
      }
      const visit = (n, parentWorld) => {
        if (parentWorld) mat4Mul(inst.nodeWorld[n], parentWorld, inst.nodeLocal[n]);
        else mat4Copy(inst.nodeWorld[n], inst.nodeLocal[n]);
        for (const child of nodes[n].children) {
          if (child >= 0 && child < nodes.length) visit(child, inst.nodeWorld[n]);
        }
      };
      for (const root of inst.asset.roots) {
        if (root >= 0 && root < nodes.length) visit(root, null);
      }
    }
  };

  const render = ({ viewMatrix, viewProjMatrix, cameraPosition, fogColor = [0.6, 0.8, 1.0], fogNear = 16, fogFar = 64 }) => {
    if (instances.length === 0) return;
    const opaque = [];
    const blend = [];
    for (const inst of instances) {
      for (let ni = 0; ni < inst.asset.nodes.length; ni += 1) {
        const node = inst.asset.nodes[ni];
        if (node.mesh < 0 || node.mesh >= inst.asset.meshes.length) continue;
        const mesh = inst.asset.meshes[node.mesh];
        mat4Mul(tmp.modelNode, inst.model, inst.nodeWorld[ni]);
        for (const prim of mesh.primitives) {
          const baseMat = inst.asset.materials[prim.materialIndex] ?? inst.asset.materials[0];
          const overrideTex = inst.textureOverridesByIndex.get(prim.materialIndex) ??
            (typeof baseMat?.name === "string" && baseMat.name.length > 0
              ? inst.textureOverridesByName.get(baseMat.name) ?? null
              : null) ??
            inst.defaultTextureOverride ??
            null;
          const mat = overrideTex
            ? {
              texture: overrideTex,
              hasTexture: true,
              factor: baseMat.factor,
              alphaMode: baseMat.alphaMode,
              alphaCutoff: baseMat.alphaCutoff,
              doubleSided: baseMat.doubleSided,
            }
            : baseMat;
          const call = { prim, mat, model: Float32Array.from(tmp.modelNode), dist: 0 };
          if (mat.alphaMode === "BLEND" || mat.factor[3] < 0.999) {
            transformPoint(tmp.worldPos, call.model, prim.center);
            const dx = tmp.worldPos[0] - cameraPosition[0];
            const dy = tmp.worldPos[1] - cameraPosition[1];
            const dz = tmp.worldPos[2] - cameraPosition[2];
            call.dist = dx * dx + dy * dy + dz * dz;
            blend.push(call);
          } else {
            opaque.push(call);
          }
        }
      }
    }
    blend.sort((a, b) => b.dist - a.dist);
    gl.useProgram(info.program);
    gl.uniformMatrix4fv(info.uView, false, viewMatrix);
    gl.uniformMatrix4fv(info.uViewProj, false, viewProjMatrix);
    gl.uniform3f(info.uFogColor, fogColor[0], fogColor[1], fogColor[2]);
    gl.uniform1f(info.uFogNear, fogNear);
    gl.uniform1f(info.uFogFar, fogFar);
    gl.uniform1i(info.uTex, 0);
    gl.frontFace(gl.CCW);
    const draw = (list, blendMode) => {
      if (blendMode) {
        gl.enable(gl.BLEND);
        gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
        gl.depthMask(false);
      } else {
        gl.disable(gl.BLEND);
        gl.depthMask(true);
      }
      for (const call of list) {
        gl.uniformMatrix4fv(info.uModel, false, call.model);
        gl.uniform1i(info.uHasTexture, call.mat.hasTexture ? 1 : 0);
        gl.uniform4f(info.uColor, call.mat.factor[0], call.mat.factor[1], call.mat.factor[2], call.mat.factor[3]);
        gl.uniform1i(info.uAlphaMask, call.mat.alphaMode === "MASK" ? 1 : 0);
        gl.uniform1f(info.uAlphaCutoff, call.mat.alphaCutoff);
        if (call.mat.doubleSided) gl.disable(gl.CULL_FACE);
        else gl.enable(gl.CULL_FACE);
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, call.mat.texture);
        gl.bindVertexArray(call.prim.vao);
        if (call.prim.indexBuf) gl.drawElements(gl.TRIANGLES, call.prim.count, call.prim.indexType, 0);
        else gl.drawArrays(gl.TRIANGLES, 0, call.prim.count);
      }
      gl.bindVertexArray(null);
      if (blendMode) {
        gl.depthMask(true);
        gl.disable(gl.BLEND);
      }
    };
    draw(opaque, false);
    draw(blend, true);
    gl.bindTexture(gl.TEXTURE_2D, null);
    gl.frontFace(gl.CW);
    gl.enable(gl.CULL_FACE);
  };

  const dispose = () => {
    for (const value of assets.values()) {
      if (!value || typeof value.then === "function") continue;
      for (const mesh of value.meshes ?? []) {
        for (const prim of mesh.primitives ?? []) {
          if (prim.vao) gl.deleteVertexArray(prim.vao);
          if (prim.posBuf) gl.deleteBuffer(prim.posBuf);
          if (prim.nBuf) gl.deleteBuffer(prim.nBuf);
          if (prim.uvBuf) gl.deleteBuffer(prim.uvBuf);
          if (prim.indexBuf) gl.deleteBuffer(prim.indexBuf);
        }
      }
      for (const tex of value.textures ?? []) {
        if (tex && tex !== whiteTexture) gl.deleteTexture(tex);
      }
    }
    for (const tex of externalTextures.values()) {
      if (tex && typeof tex.then !== "function") {
        gl.deleteTexture(tex);
      }
    }
    gl.deleteTexture(whiteTexture);
    gl.deleteProgram(info.program);
    instances.length = 0;
    assets.clear();
    externalTextures.clear();
  };

  return {
    loadFromConfigs,
    update,
    render,
    setAnimation,
    setTexture,
    getEntityIds,
    dispose,
    getInstanceCount: () => instances.length,
  };
}

export {
  DEFAULT_MANIFEST_URL,
  createGltfEntityRenderer,
  loadEntityConfigs,
};
