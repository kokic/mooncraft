const GLTF_TRIANGLES = 4;
const DEFAULT_MANIFEST_URL = "./assets/models/entities.json";
const LOOK_EPSILON = 1e-6;
const LOOK_PITCH_LIMIT = Math.PI * 0.499;
const ENTITY_YAW_OFFSET = Math.PI;


function decodeDataUri(uri) {
  const comma = uri.indexOf(",");
  if (comma < 0) throw new Error("invalid data uri");
  const data = atob(uri.slice(comma + 1));
  const out = new Uint8Array(data.length);
  for (let i = 0; i < data.length; i += 1) out[i] = data.charCodeAt(i);
  return out.buffer;
}

async function loadGltfPayload(url) {
  const absUrl = new URL(url, window.location.href).href;
  const res = await fetch(absUrl);
  if (!res.ok) throw new Error(`failed to fetch glb: ${absUrl}`);
  if (absUrl.toLowerCase().endsWith(".glb")) {
    const parsed = window.mcParseGlb(await res.arrayBuffer());
    const gltf = JSON.parse(parsed.json_text);
    return { url: absUrl, baseUrl: absUrl, gltf, glbBin: parsed.bin_data };
  }
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
    textures[i] = img
      ? window.mcCreateTextureFromImage(gl, img, sampler?.minFilter ?? 9728, sampler?.magFilter ?? 9728, sampler?.wrapS ?? 33071, sampler?.wrapT ?? 33071)
      : whiteTexture;
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
  const {
    mcMat4Create: mat4Create,
    mcMat4Copy: mat4Copy,
    mcMat4Mul: mat4Mul,
    mcMat4FromTRS: mat4FromTRS,
    mcTransformPoint: transformPoint,
    mcQuatNormalize: quatNormalize,
    mcQuatMul: quatMul,
    mcQuatApplyYawOffset: quatApplyYawOffset,
    mcQuatFromYawPitch: quatFromYawPitch,
    mcQuatSlerp: quatSlerp,
  } = window;
  const info = window.mcCreateGltfProgram(gl, window.mcGltfVsSource, window.mcGltfFsSource);
  const whiteTexture = window.mcCreateWhiteTexture(gl);
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
      return window.mcCreateTextureFromImage(gl, image, 9728, 9728, 33071, 33071);
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
      const animations = (gltf.animations ?? []).map((def, i) => {
        const channels = (def.channels ?? []).map((ch) => {
          const sampler = def.samplers?.[ch.sampler];
          if (!sampler) return null;
          const node = ch.target?.node;
          const path = ch.target?.path === "position" ? "translation" : ch.target?.path;
          if (!Number.isInteger(node)) return null;
          if (path !== "translation" && path !== "rotation" && path !== "scale") return null;
          const readAnimAccessor = (accessorIndex, comps) => {
            const acc = gltf.accessors?.[accessorIndex];
            if (!acc) return null;
            const view = gltf.bufferViews?.[acc.bufferView];
            if (!view) return null;
            const buf = buffers[view.buffer];
            if (!buf) return null;
            return window.mcReadAccessorValues(buf, acc.componentType, acc.type, acc.count, acc.byteOffset ?? 0, view.byteStride ?? 0);
          };
          const input = readAnimAccessor(sampler.input, 1);
          const comps = path === "rotation" ? 4 : 3;
          const outputRaw = readAnimAccessor(sampler.output, comps);
          if (!input || !outputRaw) return null;
          let output = outputRaw;
          let interp = sampler.interpolation ?? "LINEAR";
          if (interp === "CUBICSPLINE") {
            const keyCount = input.length;
            if (outputRaw.length >= keyCount * comps * 3) {
              const reduced = new Float32Array(keyCount * comps);
              for (let k = 0; k < keyCount; k += 1) {
                const src = (k * 3 + 1) * comps;
                for (let c2 = 0; c2 < comps; c2 += 1) reduced[k * comps + c2] = outputRaw[src + c2];
              }
              output = reduced;
              interp = "LINEAR";
            } else { interp = "LINEAR"; }
          }
          const duration = Number(input[input.length - 1]) || 0;
          return { node, path, interpolation: interp, input, output };
        }).filter(Boolean);
        const duration = channels.reduce((max, ch) => Math.max(max, Number(ch.input[ch.input.length - 1]) || 0), 0);
        return { name: typeof def.name === "string" ? def.name : `animation_${i}`, duration, channels };
      });
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
      const readAttr = (accessorIndex) => {
        const acc = gltf.accessors?.[accessorIndex];
        if (!acc) return null;
        const view = gltf.bufferViews?.[acc.bufferView];
        if (!view) throw new Error(`missing bufferView for accessor ${accessorIndex}`);
        const buf = buffers[view.buffer];
        if (!buf) throw new Error(`missing buffer payload ${view.buffer}`);
        return window.mcReadAccessorValues(buf, acc.componentType, acc.type, acc.count ?? 0, acc.byteOffset ?? 0, view.byteStride ?? 0);
      };
      const readIdx = (accessorIndex) => {
        const acc = gltf.accessors?.[accessorIndex];
        if (!acc) return null;
        const view = gltf.bufferViews?.[acc.bufferView];
        if (!view) return null;
        const buf = buffers[view.buffer];
        if (!buf) return null;
        return window.mcReadIndices(buf, acc.componentType, acc.count ?? 0, (view.byteOffset ?? 0) + (acc.byteOffset ?? 0), view.byteStride ?? 0);
      };
      const meshes = (gltf.meshes ?? []).map((mesh) => {
        const primitives = [];
        for (const prim of mesh?.primitives ?? []) {
          const mode = Number.isFinite(Number(prim.mode)) ? Number(prim.mode) : GLTF_TRIANGLES;
          if (mode !== GLTF_TRIANGLES) continue;
          const attrs = prim.attributes ?? {};
          if (!Number.isInteger(attrs.POSITION)) continue;
          const pos = readAttr(attrs.POSITION);
          if (!pos) continue;
          const normal = Number.isInteger(attrs.NORMAL) ? readAttr(attrs.NORMAL) : null;
          const uv0 = Number.isInteger(attrs.TEXCOORD_0) ? readAttr(attrs.TEXCOORD_0) : null;
          const indices = Number.isInteger(prim.indices) ? readIdx(prim.indices) : null;
          const materialIndex = Number.isInteger(prim.material) ? prim.material : 0;
          const primInst = window.mcBuildGltfPrimitive(gl, info, pos, normal, uv0, indices, materialIndex);
          primitives.push(primInst);
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
      }
      if (Array.isArray(cfg.texture_overrides)) {
        for (const entry of cfg.texture_overrides) {
          const index = entry?.index;
          if (!Number.isInteger(index) || index < 0) continue;
          const url = entry?.texture;
          if (typeof url !== "string" || url.length === 0) continue;
          try {
            const tex = await loadExternalTexture(url);
            if (tex) textureOverridesByIndex.set(index, tex);
          } catch (err) {
            console.warn("[gltf] failed to load texture override", index, url, err);
          }
        }
      }
      if (Array.isArray(cfg.material_texture_overrides)) {
        for (const entry of cfg.material_texture_overrides) {
          const name = entry?.material;
          const url = entry?.texture;
          if (typeof name !== "string" || name.length === 0) continue;
          if (typeof url !== "string" || url.length === 0) continue;
          try {
            const tex = await loadExternalTexture(url);
            if (tex) textureOverridesByName.set(name, tex);
            if (!knownMaterialNames.has(name)) {
              console.warn("[gltf] unknown material name in material_texture_overrides", name, cfg.url);
            }
          } catch (err) {
            console.warn("[gltf] failed to load material texture override", name, url, err);
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
          "[gltf] model has no embedded texture; specify `texture`, `texture_overrides`, or `material_texture_overrides`",
          cfg.url,
        );
        continue;
      }
      const nodeLocal = asset.nodes.map(() => mat4Create());
      const nodeWorld = asset.nodes.map(() => mat4Create());
      const model = mat4Create();
      const pos = Array.isArray(cfg.position) ? [Number(cfg.position[0]) || 0, Number(cfg.position[1]) || 0, Number(cfg.position[2]) || 0] : [0, 0, 0];
      const cfgRot = Array.isArray(cfg.rotation) ? quatNormalize([0, 0, 0, 1], [Number(cfg.rotation[0]) || 0, Number(cfg.rotation[1]) || 0, Number(cfg.rotation[2]) || 0, Number(cfg.rotation[3]) || 1]) : [0, 0, 0, 1];
      const rot = quatApplyYawOffset([0, 0, 0, 1], cfgRot, ENTITY_YAW_OFFSET);
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
        modelPos: [pos[0], pos[1], pos[2]],
        modelRot: [rot[0], rot[1], rot[2], rot[3]],
        modelScale: [sc[0], sc[1], sc[2]],
        baseModelRot: [rot[0], rot[1], rot[2], rot[3]],
        lookYaw: 0,
        lookPitch: 0,
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
    if (typeof entityId === "string") return instances.find((inst) => inst.id === entityId) ?? null;
    return instances[entityId] ?? null;
  };

  const updateInstanceModel = (inst) => {
    if (!inst) return false;
    if (!Array.isArray(inst.modelPos) || inst.modelPos.length < 3) return false;
    if (!Array.isArray(inst.modelRot) || inst.modelRot.length < 4) return false;
    if (!Array.isArray(inst.modelScale) || inst.modelScale.length < 3) return false;
    quatNormalize(inst.modelRot, inst.modelRot);
    mat4FromTRS(inst.model, inst.modelPos, inst.modelRot, inst.modelScale);
    return true;
  };

  const solveLookAngles = (
    from,
    to,
    withPitch,
    currentYaw = 0,
    currentPitch = 0,
  ) => {
    const dx = Number(to[0]) - Number(from[0]);
    const dy = Number(to[1]) - Number(from[1]);
    const dz = Number(to[2]) - Number(from[2]);
    if (!Number.isFinite(dx) || !Number.isFinite(dy) || !Number.isFinite(dz)) {
      return null;
    }
    const horiz = Math.hypot(dx, dz);
    const dist = Math.hypot(horiz, dy);
    if (dist <= LOOK_EPSILON) {
      return {
        yaw: currentYaw,
        pitch: withPitch ? currentPitch : 0,
      };
    }
    const yaw = horiz <= LOOK_EPSILON ? currentYaw : Math.atan2(dz, dx);
    let pitch = withPitch
      ? Math.atan2(dy, Math.max(horiz, LOOK_EPSILON))
      : currentPitch;
    pitch = Math.max(-LOOK_PITCH_LIMIT, Math.min(LOOK_PITCH_LIMIT, pitch));
    return { yaw, pitch };
  };

  const applyLookRotation = (inst, yaw, pitch) => {
    if (!inst) return false;
    if (!Number.isFinite(yaw) || !Number.isFinite(pitch)) return false;
    const lookRot = [0, 0, 0, 1];
    quatFromYawPitch(lookRot, yaw, pitch);
    quatMul(inst.modelRot, lookRot, inst.baseModelRot ?? [0, 0, 0, 1]);
    inst.lookYaw = yaw;
    inst.lookPitch = pitch;
    return updateInstanceModel(inst);
  };

  const setRotationQuat = (entityId, x, y, z, w) => {
    const inst = getInstanceById(entityId);
    if (!inst) {
      console.warn("[gltf] setRotationQuat: entity not found", entityId);
      return false;
    }
    const q = [Number(x), Number(y), Number(z), Number(w)];
    if (!Number.isFinite(q[0]) || !Number.isFinite(q[1]) ||
      !Number.isFinite(q[2]) || !Number.isFinite(q[3])) {
      console.warn("[gltf] setRotationQuat: invalid quaternion", q, "entity:", inst.id);
      return false;
    }
    quatNormalize(q, q);
    quatApplyYawOffset(inst.modelRot, q, ENTITY_YAW_OFFSET);
    return updateInstanceModel(inst);
  };

  const setYaw = (entityId, yaw) => {
    const inst = getInstanceById(entityId);
    if (!inst) {
      console.warn("[gltf] setYaw: entity not found", entityId);
      return false;
    }
    const yawValue = Number(yaw);
    if (!Number.isFinite(yawValue)) {
      console.warn("[gltf] setYaw: invalid yaw", yaw, "entity:", inst.id);
      return false;
    }
    const pitch = Number.isFinite(inst.lookPitch) ? inst.lookPitch : 0;
    return applyLookRotation(inst, yawValue, pitch);
  };

  const setScale = (entityId, x, y, z) => {
    const inst = getInstanceById(entityId);
    if (!inst) {
      console.warn("[gltf] setScale: entity not found", entityId);
      return false;
    }
    const sx = Number(x);
    const sy = Number(y);
    const sz = Number(z);
    if (!Number.isFinite(sx) || !Number.isFinite(sy) || !Number.isFinite(sz)) {
      console.warn("[gltf] setScale: invalid scale", [x, y, z], "entity:", inst.id);
      return false;
    }
    if (Math.abs(sx) <= LOOK_EPSILON || Math.abs(sy) <= LOOK_EPSILON || Math.abs(sz) <= LOOK_EPSILON) {
      console.warn("[gltf] setScale: zero scale is not allowed", [sx, sy, sz], "entity:", inst.id);
      return false;
    }
    inst.modelScale[0] = sx;
    inst.modelScale[1] = sy;
    inst.modelScale[2] = sz;
    return updateInstanceModel(inst);
  };

  const lookAt = (entityId, tx, ty, tz, withPitch = true) => {
    const inst = getInstanceById(entityId);
    if (!inst) {
      console.warn("[gltf] lookAt: entity not found", entityId);
      return false;
    }
    const target = [Number(tx), Number(ty), Number(tz)];
    if (!Number.isFinite(target[0]) || !Number.isFinite(target[1]) || !Number.isFinite(target[2])) {
      console.warn("[gltf] lookAt: invalid target", target, "entity:", inst.id);
      return false;
    }
    const solved = solveLookAngles(
      inst.modelPos,
      target,
      withPitch,
      Number.isFinite(inst.lookYaw) ? inst.lookYaw : 0,
      Number.isFinite(inst.lookPitch) ? inst.lookPitch : 0,
    );
    if (!solved) return false;
    return applyLookRotation(inst, solved.yaw, solved.pitch);
  };

  const lookAtXz = (entityId, tx, tz) => {
    const inst = getInstanceById(entityId);
    if (!inst) {
      console.warn("[gltf] lookAtXz: entity not found", entityId);
      return false;
    }
    return lookAt(
      entityId,
      tx,
      inst.modelPos[1],
      tz,
      false,
    );
  };

  const lookAtXyz = (entityId, tx, ty, tz) => lookAt(entityId, tx, ty, tz, true);

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
    setRotationQuat,
    setYaw,
    setScale,
    lookAtXz,
    lookAtXyz,
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
