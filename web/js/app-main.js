import { loadBlockTextures } from "./block-textures.js";
import { renderTestChunk } from "./world-renderer.js";
import { createSaveMenu } from "./save-manager.js";
import { createSaveWriter, parseSavePayload } from "./save-store.js";
import { initializeGlobalConstants, launchGame } from "virtual:mooncraft-runtime";
import { getWorldTypeNames } from "virtual:mooncraft-level";

initializeGlobalConstants();

const DEFAULT_WORLD_TYPE = getWorldTypeNames()[0]

function randomWorldSeed() {
  if (typeof globalThis.crypto?.getRandomValues === "function") {
    const value = new Uint32Array(1);
    globalThis.crypto.getRandomValues(value);
    return value[0];
  }
  return Date.now() >>> 0;
}

function defaultInfiniteWorldHeight() {
  const height = Number(globalThis.mcInfiniteWorldDefaultHeight);
  if (!Number.isSafeInteger(height)) {
    throw new Error("Infinite world height configuration is unavailable");
  }
  return height;
}

function launchRequest(slot) {
  const saved = parseSavePayload(slot.payload);
  if (slot.payload !== null && !saved) {
    throw new Error(`Save "${slot.name}" has an invalid payload`);
  }
  if (saved) {
    return {
      seed: saved.seed,
      worldType: saved.worldType,
      height: saved.height,
      saveText: slot.payload,
    };
  }
  return {
    seed: randomWorldSeed(),
    worldType: slot.newWorldType ?? DEFAULT_WORLD_TYPE,
    height: Number.isSafeInteger(slot.newWorldHeight)
      ? slot.newWorldHeight
      : defaultInfiniteWorldHeight(),
    saveText: "",
  };
}

function loadBlockGltfModels() {
  return new Promise((resolve, reject) => {
    if (typeof window.mcLoadBlockGltfModels !== "function") {
      reject(new Error("mcLoadBlockGltfModels is unavailable"));
      return;
    }
    window.mcLoadBlockGltfModels((message) => {
      if (message === "") resolve();
      else reject(new Error(message));
    });
  });
}

async function bootstrap(slot) {
  const launch = launchRequest(slot);
  launchGame(launch.seed, launch.worldType, launch.height, launch.saveText);
  const textures = await loadBlockTextures();
  window.mcTextures = textures;
  await loadBlockGltfModels();
  const chunkSize = window.mcChunkSize;
  const saveWriter = createSaveWriter(slot.id);
  let session = null;
  session = renderTestChunk({
    blockRegistry: window.mcBlocks,
    textures,
    chunkSize,
    onSaveAndQuit: async (payload) => {
      await saveWriter.enqueue(payload);
      const menu = await createSaveMenuNode();
      session.dispose();
      document.body.appendChild(menu);
    },
  });
}

async function createSaveMenuNode() {
  let menu = null;
  menu = await createSaveMenu({
    onOpen: (slot) => {
      menu.remove();
      bootstrap(slot).catch((err) => { console.error(err); });
    },
  });
  return menu;
}

async function showSaveMenu() {
  document.body.appendChild(await createSaveMenuNode());
}

async function start() {
  await showSaveMenu();
}

start();
