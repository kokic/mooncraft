import { logOnce } from "./logging.js";

// Widgets atlas metadata (pixel coords in the 256x256 source image).
const HOTBAR_BG = { x: 0, y: 0, width: 182, height: 22 };
const SELECTOR_BG = { x: 0, y: 22, width: 24, height: 24 };
const WIDGETS_BASE_SIZE = 256;
// Icon rendering: base geometry is authored for 32x32; canvas can be larger for sharper pixels.
const ICON_BASE_SIZE = 32;
const ICON_CANVAS_SIZE = 48;
// Visual size in the UI (CSS pixels).
const ICON_DISPLAY_SIZE = 20;
// Flat item draw size within the canvas (before CSS scaling).
const ICON_FLAT_SIZE = 20;
// Scale factor applied to isometric block geometry.
const ICON_SCALE = ICON_CANVAS_SIZE / ICON_BASE_SIZE;

// Crop the widgets atlas into a data URL for CSS backgrounds.
function createCroppedDataUrl(img, crop) {
  const scale = img.width / WIDGETS_BASE_SIZE;
  const canvas = document.createElement("canvas");
  canvas.width = crop.width;
  canvas.height = crop.height;
  const ctx = canvas.getContext("2d");

  ctx.drawImage(
    img,
    crop.x * scale,
    crop.y * scale,
    crop.width * scale,
    crop.height * scale,
    0,
    0,
    crop.width,
    crop.height,
  );
  return canvas.toDataURL();
}

// Force nearest-neighbor sampling for crisp pixels.
function setImageSmoothingEnabled(ctx, value) {
  ctx.mozImageSmoothingEnabled = value;
  ctx.webkitImageSmoothingEnabled = value;
  ctx.msImageSmoothingEnabled = value;
  ctx.imageSmoothingEnabled = value;
  ctx.oImageSmoothingEnabled = value;
};

// Lookup a texture image by name from the texture pack.
function resolveTextureImage(textures, name) {
  if (!textures) {
    logOnce("error", "hotbar:textures-missing", "[hotbar] textures not loaded");
    return null;
  }
  if (!name) {
    logOnce("warn", "hotbar:texture-name-missing", "[hotbar] texture name missing");
    return null;
  }
  const index = textures.textureIndex?.get(name);
  if (!Number.isFinite(index)) {
    logOnce("warn", `hotbar:texture-index-missing:${name}`, "[hotbar] texture not found", name);
    return null;
  }
  const img = textures.images?.[index] ?? null;
  if (!img) {
    logOnce("warn", `hotbar:texture-image-missing:${name}`, "[hotbar] texture image missing", name);
    return null;
  }
  return img;
}

// Draw a textured quad using a custom 2D basis (axisX/axisY) and origin.
function drawTextureFace(ctx, img, rect, origin, axisX, axisY, alpha = 1, scale = 1) {
  if (!img) return;
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

// Render a block icon with 3 faces: left, right, top (isometric).
function drawIsometricBlock(ctx, textures, item) {
  const resolvedTop = resolveTextureImage(textures, item.top?.name);
  const resolvedSide = resolveTextureImage(textures, item.side?.name);
  const topImg = resolvedTop ?? resolvedSide;
  const sideImg = resolvedSide ?? resolvedTop;
  const topRect = item.top?.rect ?? item.side?.rect;
  const sideRect = item.side?.rect ?? item.top?.rect;

  ctx.save();
  setImageSmoothingEnabled(ctx, false);
  ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);

  // Base anchor in the 32x32 geometry space (scaled by ICON_SCALE during draw).
  const cx = ICON_BASE_SIZE / 2;
  const cy = 12;

  // Draw far (left) face first for correct overlap.
  drawTextureFace(
    ctx,
    sideImg,
    sideRect,
    [cx - 8, cy - 4],
    [8, 4],
    [0, 8],
    1,
    ICON_SCALE
  );

  // Draw right face next.
  drawTextureFace(
    ctx,
    sideImg,
    sideRect,
    [cx + 8, cy - 4],
    [-8, 4],
    [0, 8],
    1,
    ICON_SCALE
  );

  // Draw top face last (closest).
  drawTextureFace(
    ctx,
    topImg,
    topRect,
    [cx, cy - 8],
    [8, 4],
    [-8, 4],
    1,
    ICON_SCALE
  );

  ctx.restore();
}

// Render a flat item sprite centered in the canvas.
function drawFlatItem(ctx, textures, item) {
  const img = resolveTextureImage(textures, item.texture?.name);
  const rect = item.texture?.rect;
  if (!img) return;
  const src = rect ?? { x: 0, y: 0, w: img.width, h: img.height };
  setImageSmoothingEnabled(ctx, false);
  ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
  // Scale to keep the same visual size even if canvas resolution changes.
  const size = (ICON_CANVAS_SIZE * ICON_FLAT_SIZE) / ICON_BASE_SIZE;
  const x = (ctx.canvas.width - size) / 2;
  const y = (ctx.canvas.height - size) / 2;
  ctx.drawImage(img, src.x, src.y, src.w, src.h, x, y, size, size);
}

// Fetch and decode the widgets atlas image.
async function loadWidgetsImage(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to load widgets.png (${response.status})`);
  }
  const blob = await response.blob();
  const img = new Image();
  await new Promise((resolve, reject) => {
    img.onload = resolve;
    img.onerror = reject;
    img.src = URL.createObjectURL(blob);
  });
  return img;
}

// Positive modulus for wrapping selection indices.
function mod(n, m) {
  return ((n % m) + m) % m;
}

// Create the hotbar DOM + canvas-based item icons.
function createHotbarUI({
  parent = document.body,
  canvas = null,
  slotCount = 9,
  widgetsUrl = new URL("../assets/images/gui/widgets.png", import.meta.url).toString(),
} = {}) {
  const host = document.createElement("div");
  host.className = "mc-hotbar";
  const root = host.attachShadow({ mode: "open" });

  // Shadow DOM template for background, selector, and item canvases.
  root.innerHTML = `
    <style>
      :host {
        --hotbar-width: clamp(220px, 45vw, 460px);
        --mc-ui-hotbar-background-img-width: ${HOTBAR_BG.width};
        --mc-ui-hotbar-background-img-height: ${HOTBAR_BG.height};
        --mc-ui-hotbar-selector-background-img-width: ${SELECTOR_BG.width};
        --mc-ui-hotbar-selector-background-img-height: ${SELECTOR_BG.height};
        --mc-ui-hotbar-item-cell-width: ${ICON_DISPLAY_SIZE};
        --mc-ui-hotbar-item-cell-height: ${ICON_DISPLAY_SIZE};
        --mc-ui-hotbar-scale-factor-per-pixel: calc(
          var(--hotbar-width) / var(--mc-ui-hotbar-background-img-width)
        );
        --offset: 0;

        position: fixed;
        display: block;
        left: 50%;
        bottom: 12px;
        transform: translateX(-50%);
        pointer-events: none;
        z-index: 5;
        width: var(--hotbar-width);
        height: calc(var(--mc-ui-hotbar-scale-factor-per-pixel) * var(--mc-ui-hotbar-background-img-height));
      }

      .hotbar-background {
        position: relative;
        width: var(--hotbar-width);
        height: calc(var(--mc-ui-hotbar-scale-factor-per-pixel) * var(--mc-ui-hotbar-background-img-height));
        background-image: var(--mc-hotbar-bg-image);
        background-size: 100% 100%;
        background-repeat: no-repeat;
        image-rendering: pixelated;
        image-rendering: crisp-edges;
        opacity: 0.85;
        filter: drop-shadow(0 2px 6px rgba(0, 0, 0, 0.4));
      }

      .selector-background {
        position: absolute;
        --width-one-pixel: var(--mc-ui-hotbar-scale-factor-per-pixel);
        --height-one-pixel: calc(100% / var(--mc-ui-hotbar-background-img-height));
        width: calc(var(--width-one-pixel) * var(--mc-ui-hotbar-selector-background-img-width));
        height: calc(var(--width-one-pixel) * var(--mc-ui-hotbar-selector-background-img-height));
        top: calc((var(--mc-ui-hotbar-background-img-height) - var(--mc-ui-hotbar-selector-background-img-height)) * var(--height-one-pixel) / 2);
        left: calc(var(--offset) * var(--mc-ui-hotbar-item-cell-width) * var(--width-one-pixel) - var(--width-one-pixel));
        background-image: var(--mc-hotbar-selector-image);
        background-size: 100% 100%;
        background-repeat: no-repeat;
        image-rendering: pixelated;
        image-rendering: crisp-edges;
        filter: drop-shadow(0 0 4px rgba(0, 0, 0, 0.5));
        z-index: 2;
      }

      .hotbar-items {
        position: absolute;
        left: 0;
        top: 0;
        width: var(--hotbar-width);
        height: calc(var(--mc-ui-hotbar-scale-factor-per-pixel) * var(--mc-ui-hotbar-background-img-height));
        pointer-events: none;
        z-index: 3;
      }

      .hotbar-item {
        position: absolute;
        --width-one-pixel: var(--mc-ui-hotbar-scale-factor-per-pixel);
        --height-one-pixel: calc(100% / var(--mc-ui-hotbar-background-img-height));
        width: calc(var(--mc-ui-hotbar-item-cell-width) * var(--width-one-pixel));
        height: calc(var(--mc-ui-hotbar-item-cell-height) * var(--width-one-pixel));
        top: calc(3 * var(--height-one-pixel));
        left: calc((var(--slot-index) * var(--mc-ui-hotbar-item-cell-width) + 1) * var(--width-one-pixel));
        display: block;
        image-rendering: pixelated;
        image-rendering: crisp-edges;
      }
    </style>
    <div class="hotbar-background"></div>
    <div class="selector-background"></div>
    <div class="hotbar-items"></div>
  `;

  parent.appendChild(host);

  const state = {
    index: 0,
    items: new Array(slotCount).fill(null),
    textures: null,
  };

  const itemsRoot = root.querySelector(".hotbar-items");
  const itemCanvases = [];
  for (let i = 0; i < slotCount; i += 1) {
    const canvas = document.createElement("canvas");
    canvas.width = ICON_CANVAS_SIZE;
    canvas.height = ICON_CANVAS_SIZE;
    canvas.className = "hotbar-item";
    canvas.style.setProperty("--slot-index", `${i}`);
    itemsRoot.appendChild(canvas);
    itemCanvases.push(canvas);
  }

  // Draw all item slots into their canvases.
  const renderItems = (textures) => {
    if (!textures) {
      logOnce("warn", "hotbar:render-textures-missing", "[hotbar] render skipped: textures missing");
      return;
    }
    for (let i = 0; i < itemCanvases.length; i += 1) {
      const canvas = itemCanvases[i];
      const ctx = canvas.getContext("2d");
      
      if (!ctx) continue;
      const item = state.items[i];
      if (!item) {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        continue;
      }
      if (item.kind === "flat") {
        drawFlatItem(ctx, textures, item);
      } else if (item.kind === "block") {
        drawIsometricBlock(ctx, textures, item);
      } else {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
      }
    }
  };

  // Move the selector background to the active slot.
  const updateOffset = () => {
    host.style.setProperty("--offset", `${state.index}`);
    window.mcHotbarSelectedIndex = state.index;
  };

  // Select a slot index with wrap-around.
  const select = (index) => {
    const next = mod(index, slotCount);
    if (state.index === next) return;
    state.index = next;
    updateOffset();
    host.dispatchEvent(new CustomEvent("hotbarselect", { detail: { index: state.index } }));
  };

  const selectNext = () => select(state.index + 1);
  const selectPrev = () => select(state.index - 1);

  const onWheel = (event) => {
    if (canvas && document.pointerLockElement && document.pointerLockElement !== canvas) return;
    if (canvas && !document.pointerLockElement && event.target !== canvas && event.target !== document.body) {
      return;
    }
    event.preventDefault();
    if (event.deltaY > 0) {
      selectNext();
    } else if (event.deltaY < 0) {
      selectPrev();
    }
  };

  const onKeyDown = (event) => {
    if (event.repeat) return;
    const code = event.code;
    if (!code.startsWith("Digit")) return;
    const digit = Number(code.slice(5));
    if (!Number.isFinite(digit)) return;
    const index = digit - 1;
    if (index < 0 || index >= slotCount) return;
    select(index);
  };

  window.addEventListener("wheel", onWheel, { passive: false });
  window.addEventListener("keydown", onKeyDown);

  const dispose = () => {
    window.removeEventListener("wheel", onWheel);
    window.removeEventListener("keydown", onKeyDown);
    host.remove();
  };

  // Load and apply hotbar background sprites, then render items.
  const loadImages = async () => {
    const img = await loadWidgetsImage(widgetsUrl);
    const bgUrl = createCroppedDataUrl(img, HOTBAR_BG);
    const selectorUrl = createCroppedDataUrl(img, SELECTOR_BG);
    host.style.setProperty("--mc-hotbar-bg-image", `url(${bgUrl})`);
    host.style.setProperty("--mc-hotbar-selector-image", `url(${selectorUrl})`);
    renderItems(state.textures);
  };

  updateOffset();

  return {
    host,
    select,
    selectNext,
    selectPrev,
    getSelectedIndex: () => state.index,
    setItems: (items, textures) => {
      state.items = Array.isArray(items) ? items.slice(0, slotCount) : [];
      while (state.items.length < slotCount) state.items.push(null);
      if (textures) state.textures = textures;
      renderItems(state.textures);
      requestAnimationFrame(() => renderItems(state.textures));
    },
    dispose,
    loadImages,
  };
}

export {
  createHotbarUI,
};
