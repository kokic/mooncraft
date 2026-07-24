const SAVE_REGISTRY_KEY = "mooncraft.saves.v1";
const DEFAULT_SAVE_STORAGE_KEY = "mooncraft.save.v2";

function readJson(key) {
  try {
    const raw = globalThis.localStorage?.getItem(key);
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    return parsed && typeof parsed === "object" ? parsed : null;
  } catch (err) {
    console.warn("[save-menu] failed to read storage", key, err);
    return null;
  }
}

function writeJson(key, value) {
  globalThis.localStorage?.setItem(key, JSON.stringify(value));
}

function saveRegistry(records) {
  writeJson(SAVE_REGISTRY_KEY, {
    version: 1,
    saves: records,
  });
}

function normalizeRecord(input) {
  if (!input || typeof input !== "object") return null;
  const key = typeof input.key === "string" ? input.key : "";
  if (key.length === 0) return null;
  const id = typeof input.id === "string" && input.id.length > 0
    ? input.id
    : key;
  return {
    id,
    key,
    name: typeof input.name === "string" && input.name.length > 0
      ? input.name
      : "Untitled World",
    createdAt: Number.isFinite(Number(input.createdAt))
      ? Number(input.createdAt)
      : 0,
  };
}

function loadRegistry() {
  const payload = readJson(SAVE_REGISTRY_KEY);
  const rawRecords = Array.isArray(payload?.saves) ? payload.saves : [];
  const records = [];
  const seen = new Set();
  for (const raw of rawRecords) {
    const record = normalizeRecord(raw);
    if (!record || seen.has(record.key)) continue;
    seen.add(record.key);
    records.push(record);
  }
  return records;
}

function makeSaveId() {
  if (globalThis.crypto?.randomUUID) {
    return globalThis.crypto.randomUUID();
  }
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 10)}`;
}

function parseSaveInfo(key) {
  const payload = readJson(key);
  if (!payload) {
    return {
      exists: false,
      seed: null,
      worldType: null,
      blockDeltaCount: 0,
      savedAt: null,
    };
  }
  const seed = Number(payload.world?.seed);
  const blockDeltas = Array.isArray(payload.block_deltas)
    ? payload.block_deltas
    : (Array.isArray(payload.blockDeltas) ? payload.blockDeltas : []);
  const savedAt = Number(payload.saved_at ?? payload.savedAt);
  return {
    exists: true,
    seed: Number.isFinite(seed) ? Math.floor(seed) : null,
    worldType: typeof (payload.world?.world_type ?? payload.world?.worldType) === "string"
      ? (payload.world.world_type ?? payload.world.worldType)
      : null,
    blockDeltaCount: blockDeltas.length,
    savedAt: Number.isFinite(savedAt) ? savedAt : null,
  };
}

function discoverSaveSlots() {
  const records = loadRegistry();
  const byKey = new Map(records.map((record) => [record.key, record]));
  if (readJson(DEFAULT_SAVE_STORAGE_KEY) && !byKey.has(DEFAULT_SAVE_STORAGE_KEY)) {
    byKey.set(DEFAULT_SAVE_STORAGE_KEY, {
      id: "default",
      key: DEFAULT_SAVE_STORAGE_KEY,
      name: "Default World",
      createdAt: 0,
    });
  }
  return Array.from(byKey.values())
    .map((record) => ({
      ...record,
      info: parseSaveInfo(record.key),
    }))
    .sort((a, b) => {
      const at = a.info.savedAt ?? a.createdAt;
      const bt = b.info.savedAt ?? b.createdAt;
      return bt - at;
    });
}

function createSaveSlot(name) {
  const now = Date.now();
  const id = makeSaveId();
  const record = {
    id,
    key: `${DEFAULT_SAVE_STORAGE_KEY}.${id}`,
    name: name || "New World",
    createdAt: now,
  };
  saveRegistry([record, ...loadRegistry()]);
  return record;
}

function deleteSaveSlot(slot) {
  if (!slot) return;
  globalThis.localStorage?.removeItem(slot.key);
  saveRegistry(loadRegistry().filter((record) => record.key !== slot.key));
}

function formatDate(timestamp) {
  if (!Number.isFinite(timestamp)) return "Never saved";
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(timestamp));
}

function describeWorld(info) {
  if (!info.exists) return "New world";
  const worldType = info.worldType ?? "Unknown";
  const seed = info.seed == null ? "unknown seed" : `seed ${info.seed}`;
  return `${worldType}, ${seed}`;
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
  meta.textContent = describeWorld(slot.info);

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

function setActiveSave(slot) {
  globalThis.mcSelectedSaveStorageKey = slot.key;
  globalThis.mcActiveSaveSlotId = slot.id;
}

function createSaveMenu({ onOpen }) {
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

  const render = () => {
    content.replaceChildren();
    const slots = discoverSaveSlots();

    const toolbar = document.createElement("div");
    toolbar.className = "mc-save-toolbar";
    const count = document.createElement("div");
    count.className = "mc-save-count";
    count.textContent = `${slots.length} save${slots.length === 1 ? "" : "s"}`;
    const create = createButton("New Save", "mc-save-new", () => {
      const record = createSaveSlot(`World ${slots.length + 1}`);
      setActiveSave(record);
      onOpen(record);
    });
    toolbar.append(count, create);
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
            setActiveSave(selected);
            onOpen(selected);
          },
          (selected) => {
            const ok = globalThis.confirm?.(`Delete "${selected.name}"?`) ?? true;
            if (!ok) return;
            deleteSaveSlot(selected);
            render();
          },
        ));
      }
    }
    content.append(list);
  };

  render();
  return root;
}

export {
  DEFAULT_SAVE_STORAGE_KEY,
  createSaveMenu,
};
