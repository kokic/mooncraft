const packLongId = (id, state = 0) => window.mcPackLongId(id, state);

const unpackLongId = (long_id) => {
  const out = window.mcUnpackLongId(long_id);
  return { id: out._0, state: out._1 };
};

function createBlockRegistry(textureIndex) {
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
