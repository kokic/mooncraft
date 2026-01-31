import { loadImage } from "./asset-loader.js";

const BLOCK_IMAGE_ROOT = "./assets/images/blocks";

function collectTextureNames() {
  if (typeof window.mcCollectTextureNames !== "function") {
    throw new Error("mcCollectTextureNames not available");
  }
  const names = window.mcCollectTextureNames();
  console.log("mcCollectTextureNames:", names);
  if (!Array.isArray(names)) {
    throw new Error("mcCollectTextureNames returned non-array");
  }
  return names;
}

async function loadBlockTextures() {
  const texture_names = collectTextureNames();
  const images = [];
  const textureIndex = new Map();

  let base_w = null;
  let base_h = null;

  for (const name of texture_names) {
    const img = await loadImage(`${BLOCK_IMAGE_ROOT}/${name}.png`);
    if (base_w == null) {
      base_w = img.width;
      base_h = img.height;
    } else if (img.width !== base_w || img.height !== base_h) {
      throw new Error(`texture size mismatch: ${name} (${img.width}x${img.height})`);
    }
    textureIndex.set(name, images.length);
    images.push(img);
  }

  return {
    images,
    textureIndex,
    singleWidth: base_w,
    singleHeight: base_h,
    layerCount: images.length,
  };
}

export {
  loadBlockTextures,
};
