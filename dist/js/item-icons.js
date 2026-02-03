const ICON_BASE_SIZE = 32;
const ICON_DEFAULT_CANVAS_SIZE = 48;
const ICON_FLAT_SIZE = 20;

function setImageSmoothingEnabled(ctx, value) {
  ctx.mozImageSmoothingEnabled = value;
  ctx.webkitImageSmoothingEnabled = value;
  ctx.msImageSmoothingEnabled = value;
  ctx.imageSmoothingEnabled = value;
  ctx.oImageSmoothingEnabled = value;
}

function resolveTextureImage(textures, name) {
  if (!textures || !textures.textureIndex || !textures.images) {
    throw new Error("resolveTextureImage: textures not ready");
  }
  const index = textures.textureIndex.get(name);
  if (!Number.isInteger(index) || index < 0 || index >= textures.images.length) {
    const sampleNames = Array.from(textures.textureIndex.keys()).slice(0, 12);
    console.error("[item-icons] texture not found", {
      name,
      hasName: textures.textureIndex.has(name),
      textureCount: textures.images.length,
      sampleNames,
    });
    throw new Error(`resolveTextureImage: texture not found: ${name}`);
  }
  return textures.images[index];
}

function drawTextureFace(ctx, img, rect, origin, axisX, axisY, alpha = 1, scale = 1) {
  const src = rect ?? { x: 0, y: 0, w: img.width, h: img.height };
  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.setTransform(
    (axisX[0] * scale) / src.w,
    (axisX[1] * scale) / src.w,
    (axisY[0] * scale) / src.h,
    (axisY[1] * scale) / src.h,
    origin[0] * scale,
    origin[1] * scale,
  );
  ctx.drawImage(img, src.x, src.y, src.w, src.h, 0, 0, src.w, src.h);
  ctx.restore();
}

function drawIsometricBlock(ctx, textures, item, options = {}) {
  let resolvedTop = null;
  let resolvedSide = null;
  try {
    resolvedTop = resolveTextureImage(textures, item.top?.name);
    resolvedSide = resolveTextureImage(textures, item.side?.name);
  } catch (err) {
    console.error("[item-icons] drawIsometricBlock resolve failed", {
      item,
      top: item.top,
      side: item.side,
      options,
    });
    throw err;
  }
  const topImg = resolvedTop ?? resolvedSide;
  const sideImg = resolvedSide ?? resolvedTop;
  const topRect = item.top?.rect ?? item.side?.rect;
  const sideRect = item.side?.rect ?? item.top?.rect;
  const baseSize = options.baseSize ?? ICON_BASE_SIZE;
  const scale = options.scale ?? (ctx.canvas.width / baseSize);

  ctx.save();
  setImageSmoothingEnabled(ctx, false);
  ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);

  const cx = baseSize / 2;
  const cy = 12;

  drawTextureFace(
    ctx,
    sideImg,
    sideRect,
    [cx - 8, cy - 4],
    [8, 4],
    [0, 8],
    1,
    scale,
  );

  drawTextureFace(
    ctx,
    sideImg,
    sideRect,
    [cx + 8, cy - 4],
    [-8, 4],
    [0, 8],
    1,
    scale,
  );

  drawTextureFace(
    ctx,
    topImg,
    topRect,
    [cx, cy - 8],
    [8, 4],
    [-8, 4],
    1,
    scale,
  );

  ctx.restore();
}

function drawFlatItem(ctx, textures, item, options = {}) {
  let img = null;
  try {
    img = resolveTextureImage(textures, item.texture?.name);
  } catch (err) {
    console.error("[item-icons] drawFlatItem resolve failed", {
      item,
      texture: item.texture,
      options,
    });
    throw err;
  }
  const rect = item.texture?.rect;
  const src = rect ?? { x: 0, y: 0, w: img.width, h: img.height };
  const baseSize = options.baseSize ?? ICON_BASE_SIZE;
  const flatSize = options.flatSize ?? ICON_FLAT_SIZE;
  setImageSmoothingEnabled(ctx, false);
  ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
  const size = (ctx.canvas.width * flatSize) / baseSize;
  const x = (ctx.canvas.width - size) / 2;
  const y = (ctx.canvas.height - size) / 2;
  ctx.drawImage(img, src.x, src.y, src.w, src.h, x, y, size, size);
}

function drawItemIcon(ctx, textures, item, options = {}) {
  if (item.kind === "flat") {
    drawFlatItem(ctx, textures, item, options);
  } else if (item.kind === "block") {
    drawIsometricBlock(ctx, textures, item, options);
  } else {
    ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
  }
}

export {
  ICON_BASE_SIZE,
  ICON_DEFAULT_CANVAS_SIZE,
  ICON_FLAT_SIZE,
  drawFlatItem,
  drawIsometricBlock,
  drawItemIcon,
  resolveTextureImage,
  setImageSmoothingEnabled,
};
