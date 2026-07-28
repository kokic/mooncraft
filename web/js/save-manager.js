import {
  createSaveSlot,
  deleteSaveSlot,
  listSaveSlots,
  parseSavePayload,
} from "./save-store.js";

function getWorldTypes() {
  const types = globalThis.mcWorldTypes;
  return Array.isArray(types) && types.length > 0
    ? types.filter((t) => typeof t === "string")
    : [];
}

function defaultWorldType() {
  const types = getWorldTypes();
  return types.length > 0 ? types[0] : "Infinite";
}

function isValidWorldType(wt) {
  return getWorldTypes().includes(wt);
}

function infiniteWorldHeightConfig() {
  const min = Number(globalThis.mcInfiniteWorldMinHeight);
  const max = Number(globalThis.mcInfiniteWorldMaxHeight);
  const defaultHeight = Number(globalThis.mcInfiniteWorldDefaultHeight);
  if (!Number.isSafeInteger(min) || !Number.isSafeInteger(max) ||
    !Number.isSafeInteger(defaultHeight) || min > max ||
    defaultHeight < min || defaultHeight > max) {
    throw new Error("Infinite world height configuration is unavailable");
  }
  return { min, max, defaultHeight };
}

function selectedInfiniteWorldHeight(input, config) {
  const height = Number(input.value);
  return Number.isSafeInteger(height) && height >= config.min && height <= config.max
    ? height
    : config.min;
}

function parseSaveInfo(text) {
  const payload = parseSavePayload(text);
  if (!payload) {
    return {
      exists: false,
      seed: null,
      worldType: null,
      height: null,
      blockDeltaCount: 0,
      savedAt: null,
    };
  }
  return {
    exists: true,
    seed: payload.seed,
    worldType: payload.worldType,
    height: payload.height,
    blockDeltaCount: payload.blockDeltaCount,
    savedAt: payload.savedAt,
  };
}

function formatDate(timestamp) {
  if (!Number.isFinite(timestamp)) return "Never saved";
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(timestamp));
}

function describeWorld(info, worldType, worldHeight) {
  if (!info.exists) {
    const height = worldType === "Infinite" && Number.isSafeInteger(worldHeight)
      ? `, height ${worldHeight}`
      : "";
    return `${worldType ?? "Unknown"}, new world${height}`;
  }
  const wt = info.worldType ?? worldType ?? "Unknown";
  const seed = info.seed == null ? "unknown seed" : `seed ${info.seed}`;
  const height = wt === "Infinite" && Number.isSafeInteger(info.height)
    ? `, height ${info.height}`
    : "";
  return `${wt}, ${seed}${height}`;
}

function createButton(label, className, onClick) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = className;
  button.textContent = label;
  button.addEventListener("click", onClick);
  return button;
}

function createSaveRow(slot, onOpen, onDelete) {
  const row = document.createElement("article");
  row.className = "mc-save-row";

  const body = document.createElement("div");
  body.className = "mc-save-body";

  const title = document.createElement("h2");
  title.textContent = slot.name;

  const meta = document.createElement("p");
  meta.className = "mc-save-meta";
  meta.textContent = describeWorld(slot.info, slot.newWorldType, slot.newWorldHeight);

  const details = document.createElement("p");
  details.className = "mc-save-details";
  details.textContent = `${slot.info.blockDeltaCount} edited blocks · ${formatDate(slot.info.savedAt ?? slot.createdAt)}`;

  body.append(title, meta, details);

  const actions = document.createElement("div");
  actions.className = "mc-save-actions";
  actions.append(
    createButton("Open", "mc-save-open", () => onOpen(slot)),
    createButton("Delete", "mc-save-delete", () => onDelete(slot)),
  );

  row.append(body, actions);
  return row;
}

function installStyles() {
  if (document.getElementById("mc-save-menu-style")) return;
  const style = document.createElement("style");
  style.id = "mc-save-menu-style";
  style.textContent = `
    :root {
      color-scheme: dark;
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #101419;
      color: #eef3f2;
    }

    body {
      margin: 0;
      min-width: 320px;
      background: #101419;
    }

    .mc-save-menu {
      min-height: 100vh;
      display: grid;
      grid-template-rows: auto 1fr;
      background:
        linear-gradient(rgba(16, 20, 25, 0.86), rgba(16, 20, 25, 0.92)),
        url("./assets/images/block/grass_side_carried.png");
      background-size: auto, 96px 96px;
    }

    .mc-save-header {
      padding: 28px clamp(18px, 5vw, 56px) 18px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.11);
      background: rgba(13, 17, 22, 0.78);
      backdrop-filter: blur(10px);
    }

    .mc-save-title {
      margin: 0;
      font-size: clamp(30px, 5vw, 56px);
      line-height: 1;
      font-weight: 800;
      letter-spacing: 0;
    }

    .mc-save-subtitle {
      margin: 10px 0 0;
      max-width: 680px;
      color: #aebcba;
      font-size: 15px;
      line-height: 1.5;
    }

    .mc-save-content {
      width: min(920px, calc(100vw - 32px));
      margin: 0 auto;
      padding: 22px 0 34px;
    }

    .mc-save-toolbar {
      display: flex;
      justify-content: space-between;
      gap: 12px;
      align-items: center;
      margin-bottom: 14px;
    }

    .mc-save-count {
      color: #aebcba;
      font-size: 14px;
    }

    .mc-save-new,
    .mc-save-open,
    .mc-save-delete {
      min-height: 38px;
      border: 1px solid rgba(255, 255, 255, 0.16);
      border-radius: 6px;
      padding: 0 15px;
      color: #f6fbfa;
      background: rgba(255, 255, 255, 0.08);
      font: inherit;
      font-size: 14px;
      cursor: pointer;
    }

    .mc-save-new,
    .mc-save-open {
      background: #2f7d58;
      border-color: #49a36f;
    }

    .mc-save-world-type {
      min-height: 38px;
      border: 1px solid rgba(255, 255, 255, 0.16);
      border-radius: 6px;
      padding: 0 12px;
      color: #f6fbfa;
      background: rgba(255, 255, 255, 0.08);
      font: inherit;
      font-size: 14px;
      cursor: pointer;
      outline: none;
    }

    .mc-save-world-height {
      width: 88px;
      min-height: 38px;
      box-sizing: border-box;
      border: 1px solid rgba(255, 255, 255, 0.16);
      border-radius: 6px;
      padding: 0 10px;
      color: #f6fbfa;
      background: rgba(255, 255, 255, 0.08);
      font: inherit;
      font-size: 14px;
      outline: none;
    }

    .mc-save-world-height:focus {
      border-color: #49a36f;
    }

    .mc-save-world-type:focus {
      border-color: #49a36f;
    }

    .mc-save-world-type option {
      background: #1a2129;
      color: #f6fbfa;
    }

    .mc-save-delete {
      color: #ffd8d8;
      background: rgba(142, 39, 39, 0.44);
      border-color: rgba(255, 124, 124, 0.32);
    }

    .mc-save-list {
      display: grid;
      gap: 10px;
    }

    .mc-save-row {
      display: grid;
      grid-template-columns: 1fr auto;
      gap: 18px;
      align-items: center;
      padding: 16px;
      border: 1px solid rgba(255, 255, 255, 0.13);
      border-radius: 8px;
      background: rgba(19, 25, 31, 0.9);
      box-shadow: 0 10px 32px rgba(0, 0, 0, 0.22);
    }

    .mc-save-body h2 {
      margin: 0;
      font-size: 19px;
      line-height: 1.25;
      letter-spacing: 0;
    }

    .mc-save-meta,
    .mc-save-details,
    .mc-save-empty {
      margin: 6px 0 0;
      color: #aebcba;
      font-size: 14px;
      line-height: 1.45;
    }

    .mc-save-actions {
      display: flex;
      gap: 8px;
      align-items: center;
    }

    .mc-save-empty {
      padding: 24px 0;
    }

    @media (max-width: 620px) {
      .mc-save-toolbar,
      .mc-save-row {
        grid-template-columns: 1fr;
      }

      .mc-save-toolbar,
      .mc-save-actions {
        align-items: stretch;
        flex-direction: column;
      }

      .mc-save-new,
      .mc-save-open,
      .mc-save-delete {
        width: 100%;
      }
    }
  `;
  document.head.appendChild(style);
}

async function createSaveMenu({ onOpen }) {
  installStyles();
  const root = document.createElement("main");
  root.className = "mc-save-menu";

  const header = document.createElement("header");
  header.className = "mc-save-header";
  const title = document.createElement("h1");
  title.className = "mc-save-title";
  title.textContent = "Mooncraft";
  const subtitle = document.createElement("p");
  subtitle.className = "mc-save-subtitle";
  subtitle.textContent = "Select a local browser save, create a new world, or delete a save slot.";
  header.append(title, subtitle);

  const content = document.createElement("section");
  content.className = "mc-save-content";
  root.append(header, content);

  const render = async () => {
    content.replaceChildren();
    const slots = (await listSaveSlots()).map((slot) => ({
      ...slot,
      info: parseSaveInfo(slot.payload),
    }));

    const toolbar = document.createElement("div");
    toolbar.className = "mc-save-toolbar";
    const count = document.createElement("div");
    count.className = "mc-save-count";
    count.textContent = `${slots.length} save${slots.length === 1 ? "" : "s"}`;

    const toolbarRight = document.createElement("div");
    toolbarRight.style.display = "flex";
    toolbarRight.style.gap = "10px";
    toolbarRight.style.alignItems = "center";
    const heightConfig = infiniteWorldHeightConfig();

    const worldTypeSelect = document.createElement("select");
    worldTypeSelect.className = "mc-save-world-type";
    const worldTypes = getWorldTypes();
    for (const wt of worldTypes) {
      const option = document.createElement("option");
      option.value = wt;
      option.textContent = wt;
      worldTypeSelect.append(option);
    }
    if (worldTypes.length === 0) {
      const def = defaultWorldType();
      const option = document.createElement("option");
      option.value = def;
      option.textContent = def;
      worldTypeSelect.append(option);
    }

    const worldHeightInput = document.createElement("input");
    worldHeightInput.className = "mc-save-world-height";
    worldHeightInput.type = "number";
    worldHeightInput.inputMode = "numeric";
    worldHeightInput.min = String(heightConfig.min);
    worldHeightInput.max = String(heightConfig.max);
    worldHeightInput.value = String(heightConfig.defaultHeight);
    worldHeightInput.setAttribute("aria-label", "Infinite world height");
    const syncWorldHeightInput = () => {
      worldHeightInput.hidden = worldTypeSelect.value !== "Infinite";
    };
    worldTypeSelect.addEventListener("change", syncWorldHeightInput);
    syncWorldHeightInput();

    const create = createButton("New Save", "mc-save-new", () => {
      const worldType = isValidWorldType(worldTypeSelect.value)
        ? worldTypeSelect.value
        : defaultWorldType();
      void createSaveSlot(
        `World ${slots.length + 1}`,
        worldType,
        worldType === "Infinite"
          ? selectedInfiniteWorldHeight(worldHeightInput, heightConfig)
          : null,
      ).then(onOpen).catch((error) => {
        console.error("[save-menu] failed to create IndexedDB save", error);
      });
    });
    toolbarRight.append(worldTypeSelect, worldHeightInput, create);
    toolbar.append(count, toolbarRight);
    content.append(toolbar);

    const list = document.createElement("div");
    list.className = "mc-save-list";
    if (slots.length === 0) {
      const empty = document.createElement("p");
      empty.className = "mc-save-empty";
      empty.textContent = "No browser saves found.";
      list.append(empty);
    } else {
      for (const slot of slots) {
        list.append(createSaveRow(
          slot,
          (selected) => {
            onOpen(selected);
          },
          (selected) => {
            const ok = globalThis.confirm?.(`Delete "${selected.name}"?`) ?? true;
            if (!ok) return;
            void deleteSaveSlot(selected.id).then(render).catch((error) => {
              console.error("[save-menu] failed to delete IndexedDB save", error);
            });
          },
        ));
      }
    }
    content.append(list);
  };

  await render();
  return root;
}

export {
  createSaveMenu,
};
