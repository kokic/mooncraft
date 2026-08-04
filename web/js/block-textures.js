import { loadImage } from "./asset-loader.js";
import * as Block from "virtual:mooncraft-block";

const BLOCK_IMAGE_ROOT = "./assets/images/block";
const ITEM_IMAGE_ROOT = "./assets/images/item";

// Shelf gap between packed tiles (keeps sampling from bleeding across tiles
// when mipmapping/anisotropic filtering is enabled later).
const ATLAS_GAP = 2;

function resolveTextureUrl(name) {
  if (typeof name === "string" && name.startsWith("item/")) {
    return `${ITEM_IMAGE_ROOT}/${name.slice(5)}.png`;
  }
  return `${BLOCK_IMAGE_ROOT}/${name}.png`;
}

async function loadBlockTextures() {
  const texture_names = Block.collectTextureNames();
  const images = [];
  const textureIndex = new Map();

  for (const name of texture_names) {
    const img = await loadImage(resolveTextureUrl(name));
    textureIndex.set(name, images.length);
    images.push(img);
  }

  const { canvas, atlasWidth, atlasHeight, rects } = packTiles(images);

  // Per-tile normalized rects in `textureIndex` order. NEAREST sampling keeps
  // the full tile visible; the shelf gap between tiles prevents bleeding into
  // a neighbor tile at the atlas boundary.
  const rectByIndex = [];
  for (let i = 0; i < images.length; i += 1) {
    const r = rects[i];
    rectByIndex.push({
      u0: r.x / atlasWidth,
      v0: r.y / atlasHeight,
      u1: (r.x + r.w) / atlasWidth,
      v1: (r.y + r.h) / atlasHeight,
    });
  }

  const result = {
    images,
    textureIndex,
    atlas: canvas,
    rectByIndex,
  };
  return result;
}

function packTiles(images) {
  const tiles = images.map((img, index) => ({
    img,
    index,
    w: img.width,
    h: img.height,
  }));
  tiles.sort((a, b) => b.h - a.h);

  const totalArea = tiles.reduce((sum, t) => sum + t.w * t.h, 0);
  let atlasWidth = 64;
  while (atlasWidth * atlasWidth < totalArea * 1.5) {
    atlasWidth *= 2;
  }

  const rects = new Array(images.length);
  let x = ATLAS_GAP;
  let y = ATLAS_GAP;
  let rowH = 0;
  for (const t of tiles) {
    if (x + t.w + ATLAS_GAP > atlasWidth) {
      x = ATLAS_GAP;
      y += rowH + ATLAS_GAP;
      rowH = 0;
    }
    rects[t.index] = { x, y, w: t.w, h: t.h };
    x += t.w + ATLAS_GAP;
    rowH = Math.max(rowH, t.h);
  }
  const atlasHeight = y + rowH + ATLAS_GAP;

  const canvas = document.createElement("canvas");
  canvas.width = atlasWidth;
  canvas.height = atlasHeight;
  const ctx = canvas.getContext("2d");
  for (const t of tiles) {
    ctx.drawImage(t.img, rects[t.index].x, rects[t.index].y);
  }

  return { canvas, atlasWidth, atlasHeight, rects };
}

function createBlockAtlasTexture(gl, textures) {
  const tex = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, tex);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.texImage2D(
    gl.TEXTURE_2D,
    0,
    gl.RGBA,
    gl.RGBA,
    gl.UNSIGNED_BYTE,
    textures.atlas,
  );
  gl.bindTexture(gl.TEXTURE_2D, null);
  return tex;
}

export {
  loadBlockTextures,
  createBlockAtlasTexture,
};
