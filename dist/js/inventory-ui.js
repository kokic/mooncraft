import { drawItemIcon, ICON_DEFAULT_CANVAS_SIZE, ICON_FLAT_SIZE } from "./item-icons.js";

function createInventoryUI({
  parent = document.body,
  textures,
  items = [],
  columns = 9,
  rows = 6,
  slotSize = 52,
  gap = 6,
  canvasSize = ICON_DEFAULT_CANVAS_SIZE,
  onSelect = null,
  onClose = null,
  onToggle = null,
  canToggle = null,
} = {}) {
  const host = document.createElement("div");
  host.className = "mc-inventory";
  host.style.position = "fixed";
  host.style.left = "0";
  host.style.top = "0";
  host.style.right = "0";
  host.style.bottom = "0";
  host.style.display = "none";
  host.style.alignItems = "center";
  host.style.justifyContent = "center";
  host.style.background = "rgba(0, 0, 0, 0.6)";
  host.style.zIndex = "8";
  host.style.pointerEvents = "auto";

  const panelWrapper = document.createElement("div");
  panelWrapper.style.position = "relative";
  panelWrapper.style.display = "inline-block";

  const nameLabel = document.createElement("div");
  nameLabel.style.position = "absolute";
  nameLabel.style.left = "0";
  nameLabel.style.top = "0";
  nameLabel.style.transform = "translate(-50%, -170%)";
  nameLabel.style.color = "#ffffff";
  nameLabel.style.font = "12px monospace";
  nameLabel.style.padding = "2px 6px";
  nameLabel.style.background = "rgba(0, 0, 0, 0.45)";
  nameLabel.style.borderRadius = "3px";
  nameLabel.style.textShadow = "0 2px 4px rgba(0, 0, 0, 0.7)";
  nameLabel.style.whiteSpace = "nowrap";
  nameLabel.style.pointerEvents = "none";
  nameLabel.style.opacity = "0";
  panelWrapper.appendChild(nameLabel);

  const panel = document.createElement("div");
  panel.style.display = "grid";
  panel.style.gridTemplateColumns = `repeat(${columns}, ${slotSize}px)`;
  panel.style.gridTemplateRows = `repeat(${rows}, ${slotSize}px)`;
  panel.style.gap = `${gap}px`;
  panel.style.padding = "18px";
  panel.style.background = "rgba(0, 0, 0, 0.35)";
  panel.style.border = "1px solid rgba(255, 255, 255, 0.08)";
  panel.style.borderRadius = "4px";
  panel.style.boxShadow = "0 12px 30px rgba(0, 0, 0, 0.45)";
  panel.style.imageRendering = "pixelated";
  panelWrapper.appendChild(panel);

  const closeButton = document.createElement("button");
  closeButton.type = "button";
  closeButton.textContent = "X";
  closeButton.style.position = "absolute";
  closeButton.style.top = "18px";
  closeButton.style.left = `calc(100% + ${gap * 2}px)`;
  closeButton.style.width = `${slotSize}px`;
  closeButton.style.height = `${slotSize}px`;
  closeButton.style.padding = "0";
  closeButton.style.border = "1px solid rgba(255, 255, 255, 0.08)";
  closeButton.style.background = "rgba(20, 20, 20, 0.8)";
  closeButton.style.color = "#fff";
  closeButton.style.font = "16px monospace";
  closeButton.style.cursor = "pointer";
  closeButton.style.boxShadow = "inset 0 0 4px rgba(0, 0, 0, 0.7)";
  closeButton.style.lineHeight = "1";
  closeButton.style.userSelect = "none";
  closeButton.style.display = "flex";
  closeButton.style.alignItems = "center";
  closeButton.style.justifyContent = "center";
  closeButton.addEventListener("click", () => {
    if (typeof onClose === "function") {
      onClose();
    }
  });
  panelWrapper.appendChild(closeButton);

  host.appendChild(panelWrapper);

  parent.appendChild(host);

  const capacity = columns * rows;
  const slotCanvases = [];
  for (let i = 0; i < capacity; i += 1) {
    const canvas = document.createElement("canvas");
    canvas.width = canvasSize;
    canvas.height = canvasSize;
    canvas.style.width = `${slotSize}px`;
    canvas.style.height = `${slotSize}px`;
    canvas.style.imageRendering = "pixelated";
    canvas.style.imageRendering = "crisp-edges";
    canvas.style.background = "rgba(20, 20, 20, 0.8)";
    canvas.style.border = "1px solid rgba(255, 255, 255, 0.08)";
    canvas.style.boxShadow = "inset 0 0 4px rgba(0, 0, 0, 0.7)";
    panel.appendChild(canvas);
    slotCanvases.push(canvas);
  }

  const state = {
    items: items.slice(),
    textures,
    open: false,
    selectedIndex: -1,
  };
  let nameFadeTimer = null;

  const renderItems = () => {
    for (let i = 0; i < slotCanvases.length; i += 1) {
      const canvas = slotCanvases[i];
      const ctx = canvas.getContext("2d");
      if (!ctx) continue;
      const item = state.items[i];
      if (!item) {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        continue;
      }
      drawItemIcon(ctx, state.textures, item, { flatSize: ICON_FLAT_SIZE });
    }
  };

  const updateSelection = () => {
    for (let i = 0; i < slotCanvases.length; i += 1) {
      const canvas = slotCanvases[i];
      if (i === state.selectedIndex) {
        canvas.style.border = "1px solid rgba(255, 255, 255, 0.7)";
        canvas.style.boxShadow = "0 0 0 2px rgba(255, 255, 255, 0.25)";
      } else {
        canvas.style.border = "1px solid rgba(255, 255, 255, 0.08)";
        canvas.style.boxShadow = "inset 0 0 4px rgba(0, 0, 0, 0.7)";
      }
    }
    updateLabel();
  };

  const resolveDisplayName = (item) => {
    const name = item?.name;
    if (!name || name === "air") return "";
    const lookup = window.mcGetItemDisplayName;
    if (typeof lookup === "function") {
      const value = lookup(name);
      if (typeof value === "string" && value.length > 0) return value;
    }
    return name;
  };

  const updateLabel = () => {
    if (!state.open || state.selectedIndex < 0 || state.selectedIndex >= slotCanvases.length) {
      if (nameFadeTimer) clearTimeout(nameFadeTimer);
      nameLabel.textContent = "";
      nameLabel.style.opacity = "0";
      nameLabel.style.transition = "none";
      return;
    }
    const item = state.items[state.selectedIndex];
    const text = resolveDisplayName(item);
    if (!text) {
      if (nameFadeTimer) clearTimeout(nameFadeTimer);
      nameLabel.textContent = "";
      nameLabel.style.opacity = "0";
      nameLabel.style.transition = "none";
      return;
    }
    const canvas = slotCanvases[state.selectedIndex];
    const rect = canvas.getBoundingClientRect();
    const wrapperRect = panelWrapper.getBoundingClientRect();
    const centerX = rect.left - wrapperRect.left + rect.width / 2;
    const top = rect.top - wrapperRect.top;
    nameLabel.textContent = text;
    nameLabel.style.left = `${centerX}px`;
    nameLabel.style.top = `${top}px`;
    nameLabel.style.transition = "none";
    nameLabel.style.opacity = "1";
    if (nameFadeTimer) clearTimeout(nameFadeTimer);
    nameFadeTimer = setTimeout(() => {
      nameLabel.style.transition = "opacity 0.5s 2s";
      nameLabel.style.opacity = "0";
    }, 10);
  };

  for (let i = 0; i < slotCanvases.length; i += 1) {
    const canvas = slotCanvases[i];
    canvas.addEventListener("click", () => {
      const item = state.items[i];
      if (!item) return;
      state.selectedIndex = i;
      updateSelection();
      if (typeof onSelect === "function") {
        onSelect(item, i);
      }
    });
  }

  const setOpen = (open) => {
    state.open = open;
    host.style.display = open ? "flex" : "none";
    if (open) {
      renderItems();
      updateSelection();
    } else {
      if (nameFadeTimer) clearTimeout(nameFadeTimer);
      nameLabel.textContent = "";
      nameLabel.style.opacity = "0";
      nameLabel.style.transition = "none";
    }
  };

  const onKeyDown = (event) => {
    if (event.code === "Escape") {
      if (!state.open) return;
      event.preventDefault();
      event.stopImmediatePropagation();
      return;
    }
    if (event.repeat) return;
    if (event.code === "KeyE") {
      if (state.open) return;
      if (typeof canToggle === "function" && !canToggle()) return;
      if (typeof onToggle === "function") {
        onToggle();
        event.preventDefault();
        event.stopImmediatePropagation();
      }
    }
  };
  const onKeyUp = (event) => {
    if (!state.open) return;
    if (event.code === "Escape") {
      event.preventDefault();
      event.stopImmediatePropagation();
    }
  };
  window.addEventListener("keydown", onKeyDown, { capture: true });
  window.addEventListener("keyup", onKeyUp, { capture: true });
  document.addEventListener("keydown", onKeyDown, { capture: true });
  document.addEventListener("keyup", onKeyUp, { capture: true });

  const setItems = (itemsNext, texturesNext) => {
    state.items = Array.isArray(itemsNext) ? itemsNext.slice(0, capacity) : [];
    while (state.items.length < capacity) state.items.push(null);
    if (texturesNext) state.textures = texturesNext;
    renderItems();
    updateSelection();
  };

  return {
    host,
    setOpen,
    setItems,
    isOpen: () => state.open,
  };
}

export {
  createInventoryUI,
};
