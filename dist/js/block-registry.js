function packLongId(id, state = 0) {
  return ((state & 0xffff) << 16) | (id & 0xffff);
}

function unpackLongId(long_id) {
  return {
    id: long_id & 0xffff,
    state: (long_id >>> 16) & 0xffff,
  };
}

function createBlockRegistry(textureIndex) {
  if (typeof window.mcCreateBlockRegistry !== "function") {
    throw new Error("mcCreateBlockRegistry not available");
  }
  const names = [];
  const indices = [];
  for (const [name, index] of textureIndex.entries()) {
    const nameStr = typeof name === "string" ? name : String(name);
    const indexNum = Number(index);
    if (nameStr.length === 0 || !Number.isFinite(indexNum)) {
      continue;
    }
    names.push(nameStr);
    indices.push(indexNum);
  }
  return window.mcCreateBlockRegistry(names, indices);
}

export {
  createBlockRegistry,
  packLongId,
  unpackLongId,
};
