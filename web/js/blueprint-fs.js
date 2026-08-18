// Browser File System Access API integration for blueprint authoring in the
// Design world. `/open` loads a local `.json` blueprint onto the design canvas;
// `/save` writes the canvas back to that file (or a newly picked one).

function designWorldBounds() {
  return [
    Number(globalThis.mcDesignWorldMinX),
    Number(globalThis.mcDesignWorldMinY),
    Number(globalThis.mcDesignWorldMinZ),
    Number(globalThis.mcDesignWorldMaxX),
    Number(globalThis.mcDesignWorldMaxY),
    Number(globalThis.mcDesignWorldMaxZ),
  ];
}

function createBlueprintFs({ getPlacementTarget, notifyBlocksChanged }) {
  let fileHandle = null;
  let openPath = null;

  const isSupported = () =>
    typeof globalThis.showOpenFilePicker === "function" &&
    typeof globalThis.showSaveFilePicker === "function";

  async function openBlueprint(name) {
    if (!isSupported()) {
      return { success: false, message: "File System Access API is unavailable" };
    }
    let handle;
    try {
      [handle] = await globalThis.showOpenFilePicker({
        types: [{ description: "Blueprint JSON", accept: { "application/json": [".json"] } }],
      });
    } catch (error) {
      if (error?.name === "AbortError") {
        return { success: false, message: "Open cancelled" };
      }
      throw error;
    }
    const text = await (await handle.getFile()).text();
    const target = getPlacementTarget();
    if (!target) {
      return { success: false, message: "No block in sight for placement" };
    }
    if (typeof globalThis.mcResetDesignWorld === "function") {
      globalThis.mcResetDesignWorld();
    }
    if (typeof globalThis.mcLoadBlueprint !== "function") {
      return { success: false, message: "Blueprint runtime is unavailable" };
    }
    const ok = globalThis.mcLoadBlueprint(text, target[0], target[1], target[2]);
    if (!ok) {
      return { success: false, message: "Blueprint failed to load" };
    }
    if (typeof notifyBlocksChanged === "function") {
      notifyBlocksChanged();
    }
    fileHandle = handle;
    openPath = handle.name;
    return {
      success: true,
      message: name.length > 0 ? `Opened ${name}` : "Opened blueprint",
    };
  }

  async function saveBlueprint(name) {
    if (!isSupported()) {
      return { success: false, message: "File System Access API is unavailable" };
    }
    if (typeof globalThis.mcExportBlueprint !== "function") {
      return { success: false, message: "Blueprint export is unavailable" };
    }
    const bounds = designWorldBounds();
    if (bounds.some((v) => !Number.isFinite(v))) {
      return { success: false, message: "Design world bounds are unavailable" };
    }
    const text = globalThis.mcExportBlueprint(name, ...bounds);
    if (typeof text !== "string" || text.length === 0) {
      return { success: false, message: "Design canvas is empty" };
    }
    let handle = fileHandle;
    if (!handle) {
      handle = await globalThis.showSaveFilePicker({
        suggestedName: `${name || "blueprint"}.json`,
        types: [{ description: "Blueprint JSON", accept: { "application/json": [".json"] } }],
      });
    }
    const writable = await handle.createWritable();
    await writable.write(text);
    await writable.close();
    fileHandle = handle;
    openPath = handle.name;
    return { success: true, message: `Saved ${openPath}` };
  }

  function handleCommand(text) {
    const trimmed = text.trim();
    if (trimmed === "/open") {
      return openBlueprint("");
    }
    if (trimmed.startsWith("/open ")) {
      return openBlueprint(trimmed.slice("/open ".length).trim());
    }
    if (trimmed === "/save") {
      return saveBlueprint("");
    }
    if (trimmed.startsWith("/save ")) {
      return saveBlueprint(trimmed.slice("/save ".length).trim());
    }
    return null;
  }

  return { handleCommand };
}

export { createBlueprintFs };
