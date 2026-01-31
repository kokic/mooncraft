import { logOnce } from "./logging.js";

const DIRS = [
  [1, 0, 0],
  [-1, 0, 0],
  [0, 1, 0],
  [0, -1, 0],
  [0, 0, 1],
  [0, 0, -1],
];

const floorDiv = (n, d) => {
  const q = Math.trunc(n / d);
  const r = n % d;
  if (r === 0) return q;
  return (r > 0) === (d > 0) ? q : q - 1;
};

const chunkKey = (cx, cy, cz) => `${cx},${cy},${cz}`;

class LightMap extends Uint8Array {
  constructor(size) {
    super(size * size * size);
    this.size = size;
  }
  idx(x, y, z) {
    return (y * this.size + z) * this.size + x;
  }
  get(x, y, z) {
    return this[this.idx(x, y, z)];
  }
  set(x, y, z, v) {
    this[this.idx(x, y, z)] = v & 0xff;
  }
  getSkylight(x, y, z) {
    return this.get(x, y, z) & 0x0f;
  }
  getTorchlight(x, y, z) {
    return (this.get(x, y, z) >> 4) & 0x0f;
  }
  getMax(x, y, z) {
    const v = this.get(x, y, z);
    const sky = v & 0x0f;
    const torch = (v >> 4) & 0x0f;
    return sky > torch ? sky : torch;
  }
  setSkylight(x, y, z, v) {
    const i = this.idx(x, y, z);
    this[i] = (this[i] & 0xf0) | (v & 0x0f);
    return v;
  }
  setTorchlight(x, y, z, v) {
    const i = this.idx(x, y, z);
    this[i] = (this[i] & 0x0f) | ((v & 0x0f) << 4);
    return v;
  }
}

function createWorldLight({
  chunkDatas,
  size,
  blockInfo,
  worldMinY,
}) {
  const lightMaps = new Map();
  const dirtyChunks = new Set();

  const getBlockInfoById = (id) => {
    const info = blockInfo.get(id);
    if (info) return info;
    return {
      opacity: 15,
      luminance: 0,
      isOpaque: true,
      isTransparent: false,
    };
  };

  const worldToChunkLocal = (wx, wy, wz) => {
    const cx = floorDiv(wx, size);
    const cy = floorDiv(wy, size);
    const cz = floorDiv(wz, size);
    const lx = wx - cx * size;
    const ly = wy - cy * size;
    const lz = wz - cz * size;
    return { cx, cy, cz, lx, ly, lz };
  };

  const getChunkData = (cx, cy, cz) => {
    return chunkDatas.get(chunkKey(cx, cy, cz)) ?? null;
  };

  const getLightMap = (cx, cy, cz) => {
    return lightMaps.get(chunkKey(cx, cy, cz)) ?? null;
  };

  const ensureLightMap = (cx, cy, cz) => {
    const key = chunkKey(cx, cy, cz);
    let map = lightMaps.get(key);
    if (!map) {
      map = new LightMap(size);
      lightMaps.set(key, map);
    }
    return map;
  };

  const getBlockInfoAt = (wx, wy, wz) => {
    const { cx, cy, cz, lx, ly, lz } = worldToChunkLocal(wx, wy, wz);
    const data = getChunkData(cx, cy, cz);
    if (!data) return null;
    if (lx < 0 || lx >= size || ly < 0 || ly >= size || lz < 0 || lz >= size) {
      return null;
    }
    const idx = (ly * size + lz) * size + lx;
    const id = data[idx] ?? 0;
    return getBlockInfoById(id);
  };

  const getSkylightAt = (wx, wy, wz) => {
    const { cx, cy, cz, lx, ly, lz } = worldToChunkLocal(wx, wy, wz);
    const map = getLightMap(cx, cy, cz);
    if (!map) return null;
    return map.getSkylight(lx, ly, lz);
  };

  const getTorchlightAt = (wx, wy, wz) => {
    const { cx, cy, cz, lx, ly, lz } = worldToChunkLocal(wx, wy, wz);
    const map = getLightMap(cx, cy, cz);
    if (!map) return null;
    return map.getTorchlight(lx, ly, lz);
  };

  const setSkylightAt = (wx, wy, wz, v) => {
    const { cx, cy, cz, lx, ly, lz } = worldToChunkLocal(wx, wy, wz);
    const map = getLightMap(cx, cy, cz);
    if (!map) return;
    const i = map.idx(lx, ly, lz);
    const next = (map[i] & 0xf0) | (v & 0x0f);
    if (map[i] === next) return;
    map[i] = next;
    dirtyChunks.add(chunkKey(cx, cy, cz));
  };

  const setTorchlightAt = (wx, wy, wz, v) => {
    const { cx, cy, cz, lx, ly, lz } = worldToChunkLocal(wx, wy, wz);
    const map = getLightMap(cx, cy, cz);
    if (!map) return;
    const i = map.idx(lx, ly, lz);
    const next = (map[i] & 0x0f) | ((v & 0x0f) << 4);
    if (map[i] === next) return;
    map[i] = next;
    dirtyChunks.add(chunkKey(cx, cy, cz));
  };

  const spreadSkylight = (queue) => {
    const max = Math.max;
    while (queue.length) {
      const { wx, wy, wz } = queue.shift();
      const csl = getSkylightAt(wx, wy, wz) ?? 0;
      const cblock = getBlockInfoAt(wx, wy, wz);
      if (!cblock) continue;
      for (const [dx, dy, dz] of DIRS) {
        const nwx = wx + dx;
        const nwy = wy + dy;
        const nwz = wz + dz;
        const ablock = getBlockInfoAt(nwx, nwy, nwz);
        if (!ablock || ablock.isOpaque) continue;
        if (csl === 15 && dy === -1 && ablock.isTransparent) {
          setSkylightAt(nwx, nwy, nwz, 15);
          queue.push({ wx: nwx, wy: nwy, wz: nwz });
          continue;
        }
        const asl = getSkylightAt(nwx, nwy, nwz) ?? 0;
        if (csl - ablock.opacity - 1 > asl) {
          setSkylightAt(nwx, nwy, nwz, max(0, csl - ablock.opacity - 1));
          queue.push({ wx: nwx, wy: nwy, wz: nwz });
        } else if (asl - cblock.opacity - 1 > csl) {
          setSkylightAt(wx, wy, wz, asl - cblock.opacity - 1);
          queue.push({ wx, wy, wz });
        }
      }
    }
  };

  const spreadTorchlight = (queue) => {
    while (queue.length) {
      const { wx, wy, wz } = queue.shift();
      const ctl = getTorchlightAt(wx, wy, wz) ?? 0;
      const cblock = getBlockInfoAt(wx, wy, wz);
      if (!cblock) continue;
      if (ctl <= 1) continue;
      for (const [dx, dy, dz] of DIRS) {
        const nwx = wx + dx;
        const nwy = wy + dy;
        const nwz = wz + dz;
        const ablock = getBlockInfoAt(nwx, nwy, nwz);
        if (!ablock || ablock.isOpaque) continue;
        const atl = getTorchlightAt(nwx, nwy, nwz) ?? 0;
        if (ctl - ablock.opacity - 1 > atl) {
          setTorchlightAt(nwx, nwy, nwz, ctl - ablock.opacity - 1);
          queue.push({ wx: nwx, wy: nwy, wz: nwz });
        } else if (atl - cblock.opacity - 1 > ctl) {
          setTorchlightAt(wx, wy, wz, atl - cblock.opacity - 1);
          queue.push({ wx, wy, wz });
        }
      }
    }
  };

  const removeSkylight = (removalQueue) => {
    const spreadQueue = [];
    while (removalQueue.length) {
      const { wx, wy, wz, level } = removalQueue.shift();
      for (const [dx, dy, dz] of DIRS) {
        const nwx = wx + dx;
        const nwy = wy + dy;
        const nwz = wz + dz;
        const ablock = getBlockInfoAt(nwx, nwy, nwz);
        if (!ablock) continue;
        const asl = getSkylightAt(nwx, nwy, nwz) ?? 0;
        if (asl === 15 && dy === -1 && ablock.isTransparent) {
          setSkylightAt(nwx, nwy, nwz, 0);
          removalQueue.push({ wx: nwx, wy: nwy, wz: nwz, level: asl });
        } else if (asl !== 0 && asl < level) {
          setSkylightAt(nwx, nwy, nwz, 0);
          removalQueue.push({ wx: nwx, wy: nwy, wz: nwz, level: asl });
        } else if (asl >= level) {
          spreadQueue.push({ wx: nwx, wy: nwy, wz: nwz });
        }
      }
    }
    return spreadQueue;
  };

  const removeTorchlight = (removalQueue) => {
    const spreadQueue = [];
    while (removalQueue.length) {
      const { wx, wy, wz, level } = removalQueue.shift();
      for (const [dx, dy, dz] of DIRS) {
        const nwx = wx + dx;
        const nwy = wy + dy;
        const nwz = wz + dz;
        const ablock = getBlockInfoAt(nwx, nwy, nwz);
        if (!ablock) continue;
        const atl = getTorchlightAt(nwx, nwy, nwz) ?? 0;
        if (atl !== 0 && atl < level && ablock.luminance === 0) {
          setTorchlightAt(nwx, nwy, nwz, 0);
          removalQueue.push({ wx: nwx, wy: nwy, wz: nwz, level: atl });
        } else if (atl >= level || ablock.luminance) {
          spreadQueue.push({ wx: nwx, wy: nwy, wz: nwz });
        }
      }
    }
    return spreadQueue;
  };

  const buildChunkLight = (cx, cy, cz) => {
    const data = getChunkData(cx, cy, cz);
    if (!data) {
      logOnce("error", "light:chunk-missing", "[light] buildChunkLight missing chunk data", { cx, cy, cz });
      return;
    }
    const map = ensureLightMap(cx, cy, cz);
    const torchQueue = [];
    for (let y = 0; y < size; y += 1) {
      for (let z = 0; z < size; z += 1) {
        for (let x = 0; x < size; x += 1) {
          const id = data[(y * size + z) * size + x] ?? 0;
          const info = getBlockInfoById(id);
          map.setSkylight(x, y, z, 0);
          const tl = info.luminance || 0;
          map.setTorchlight(x, y, z, tl);
          if (tl) {
            torchQueue.push({ wx: cx * size + x, wy: cy * size + y, wz: cz * size + z });
          }
        }
      }
    }
    spreadTorchlight(torchQueue);
    const skyQueue = [];
    const ranges = [
      [0, size - 1, 0, 0, 0, size - 1],
      [0, size - 1, size - 1, size - 1, 0, size - 1],
      [0, 0, 0, size - 1, 0, size - 1],
      [size - 1, size - 1, 0, size - 1, 0, size - 1],
      [0, size - 1, 0, size - 1, 0, 0],
      [0, size - 1, 0, size - 1, size - 1, size - 1],
    ];
    for (const [sx, ex, sy, ey, sz, ez] of ranges) {
      const dx = sx === ex ? (sx ? 1 : -1) : 0;
      const dy = sy === ey ? (sy ? 1 : -1) : 0;
      const dz = sz === ez ? (sz ? 1 : -1) : 0;
      for (let rx = sx; rx <= ex; rx += 1) {
        for (let ry = sy; ry <= ey; ry += 1) {
          for (let rz = sz; rz <= ez; rz += 1) {
            const id = data[(ry * size + rz) * size + rx] ?? 0;
            const info = getBlockInfoById(id);
            if (info.isOpaque) continue;
            const wx = cx * size + rx;
            const wy = cy * size + ry;
            const wz = cz * size + rz;
            const asl = getSkylightAt(wx + dx, wy + dy, wz + dz);
            if (asl == null && dy !== 1) continue;
            const csl = map.getSkylight(rx, ry, rz);
            const l = Math.max(
              csl,
              dy === 1 && (asl == null || asl === 15)
                ? 15
                : (asl ?? 0) - info.opacity - 1,
            );
            if (l > 1) {
              map.setSkylight(rx, ry, rz, l);
              skyQueue.push({ wx, wy, wz });
            }
          }
        }
      }
    }
    spreadSkylight(skyQueue);
    dirtyChunks.add(chunkKey(cx, cy, cz));
  };

  const updateTile = (wx, wy, wz) => {
    const cblock = getBlockInfoAt(wx, wy, wz);
    if (!cblock) {
      logOnce("warn", "light:update-missing-block", "[light] updateTile missing block info", { wx, wy, wz });
      return;
    }
    let obstructed = wy;
    let oblock = null;
    while (true) {
      const info = getBlockInfoAt(wx, ++obstructed, wz);
      if (!info) break;
      oblock = info;
      if (info.isTransparent) break;
    }
    for (let y = obstructed - 1; y >= worldMinY - 1; y -= 1) {
      const info = getBlockInfoAt(wx, y, wz);
      if (!info || info.isTransparent) break;
      if (oblock) {
        setSkylightAt(wx, y, wz, 0);
      } else if (getSkylightAt(wx, y, wz) !== 15) {
        setSkylightAt(wx, y, wz, 15);
      }
    }
    const removalQueue = [];
    const oldSky = getSkylightAt(wx, wy, wz) ?? 0;
    removalQueue.push({ wx, wy, wz, level: oldSky });
    setSkylightAt(wx, wy, wz, oblock == null ? 15 - cblock.opacity : 0);
    const skyQueue = removeSkylight(removalQueue);
    spreadSkylight(skyQueue);

    const oldTorch = getTorchlightAt(wx, wy, wz) ?? 0;
    if (oldTorch > cblock.luminance) {
      const removeTorchQueue = [{ wx, wy, wz, level: oldTorch }];
      setTorchlightAt(wx, wy, wz, 0);
      const torchQueue = removeTorchlight(removeTorchQueue);
      spreadTorchlight(torchQueue);
    }
    setTorchlightAt(wx, wy, wz, cblock.luminance);
    if (!cblock.luminance) {
      const torchQueue = [];
      for (const [dx, dy, dz] of DIRS) {
        const nwx = wx + dx;
        const nwy = wy + dy;
        const nwz = wz + dz;
        const l = getTorchlightAt(nwx, nwy, nwz);
        if (l != null && l !== 0) {
          torchQueue.push({ wx: nwx, wy: nwy, wz: nwz });
        }
      }
      spreadTorchlight(torchQueue);
    } else {
      spreadTorchlight([{ wx, wy, wz }]);
    }
  };

  const onChunkLoaded = (cx, cy, cz) => {
    buildChunkLight(cx, cy, cz);
    for (const [dx, dy, dz] of DIRS) {
      const nx = cx + dx;
      const ny = cy + dy;
      const nz = cz + dz;
      if (getChunkData(nx, ny, nz)) {
        buildChunkLight(nx, ny, nz);
      }
    }
  };

  const getChunkLight = (cx, cy, cz) => {
    const map = getLightMap(cx, cy, cz);
    if (!map) return null;
    return map;
  };

  const consumeDirtyChunks = () => {
    const out = Array.from(dirtyChunks);
    dirtyChunks.clear();
    return out;
  };

  return {
    onChunkLoaded,
    updateTile,
    getChunkLight,
    consumeDirtyChunks,
    dropChunk: (key) => {
      lightMaps.delete(key);
      dirtyChunks.delete(key);
    },
  };
}

export {
  createWorldLight,
  LightMap,
};
