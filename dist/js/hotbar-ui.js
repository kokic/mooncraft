import { drawItemIcon, ICON_DEFAULT_CANVAS_SIZE } from "./item-icons.js";

// Widgets atlas metadata (pixel coords in the 256x256 source image).
const HOTBAR_BG = { x: 0, y: 0, width: 182, height: 22 };
const SELECTOR_BG = { x: 0, y: 22, width: 24, height: 24 };
const WIDGETS_BASE_SIZE = 256;
// Icon rendering: base geometry is authored for 32x32; canvas can be larger for sharper pixels.
const ICON_CANVAS_SIZE = ICON_DEFAULT_CANVAS_SIZE;
// Visual size in the UI (CSS pixels).
const ICON_DISPLAY_SIZE = 20;
// Flat item draw size within the canvas (before CSS scaling).
const ICON_FLAT_SIZE = 20;

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
  const renderItemAt = (index, textures) => {
    const canvas = itemCanvases[index];
    const ctx = canvas?.getContext("2d");
    if (!ctx) return;
    const item = state.items[index];
    if (!item) {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      return;
    }
    drawItemIcon(ctx, textures, item, { flatSize: ICON_FLAT_SIZE });
  };

  const renderItems = (textures) => {
    if (!textures) {
      logOnce("warn", "hotbar:render-textures-missing", "[hotbar] render skipped: textures missing");
      return;
    }
    for (let i = 0; i < itemCanvases.length; i += 1) {
      renderItemAt(i, textures);
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
    setItem: (index, item, textures) => {
      if (index < 0 || index >= slotCount) return;
      if (textures) state.textures = textures;
      state.items[index] = item ?? null;
      renderItemAt(index, state.textures);
      requestAnimationFrame(() => renderItemAt(index, state.textures));
    },
    dispose,
    loadImages,
  };
}

export {
  createHotbarUI,
};
