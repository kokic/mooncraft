import { loadImage } from "./asset-loader.js";
import * as Block from "virtual:mooncraft-block";

const BLOCK_IMAGE_ROOT = "./assets/images/block";
const ITEM_IMAGE_ROOT = "./assets/images/item";

// Width of the self-edge border padded around each packed tile. The border is
// filled with the tile's own edge texels so that a seam sampling at the tile
// boundary picks the tile's edge color instead of a neighbor tile or a
// transparent gap (which the block shader would discard, leaving a white line).
const ATLAS_PAD = 2;

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

  // Pack edge-padded tiles so tiles are adjacent (no transparent gap).
  const padded = images.map(padTile);
  const { canvas, atlasWidth, atlasHeight, rects } = packTiles(padded);

  // Per-tile normalized content rects in `textureIndex` order (inset by the
  // self-edge border).
  const rectByIndex = [];
  for (let i = 0; i < images.length; i += 1) {
    const r = rects[i];
    rectByIndex.push({
      u0: (r.x + ATLAS_PAD) / atlasWidth,
      v0: (r.y + ATLAS_PAD) / atlasHeight,
      u1: (r.x + r.w - ATLAS_PAD) / atlasWidth,
      v1: (r.y + r.h - ATLAS_PAD) / atlasHeight,
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

function padTile(img) {
  const w = img.width;
  const h = img.height;
  const canvas = document.createElement("canvas");
  canvas.width = w + ATLAS_PAD * 2;
  canvas.height = h + ATLAS_PAD * 2;
  const ctx = canvas.getContext("2d");
  ctx.imageSmoothingEnabled = false;
  // Nearest upscale fills the border with the image's edge texels; the exact
  // draw on top restores the content area.
  ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
  ctx.drawImage(img, ATLAS_PAD, ATLAS_PAD);
  return canvas;
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
  let x = 0;
  let y = 0;
  let rowH = 0;
  for (const t of tiles) {
    if (x + t.w > atlasWidth) {
      x = 0;
      y += rowH;
      rowH = 0;
    }
    rects[t.index] = { x, y, w: t.w, h: t.h };
    x += t.w;
    rowH = Math.max(rowH, t.h);
  }
  const atlasHeight = y + rowH;

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
