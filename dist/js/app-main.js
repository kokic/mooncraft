import { loadBlockTextures } from "./block-textures.js";
import { createBlockRegistry } from "./block-registry.js";
import { renderTestChunk } from "./world-renderer.js?v=indexeddb-v1";
import { createSaveMenu } from "./save-manager.js?v=indexeddb-v1";
import { createSaveWriter, parseSavePayload } from "./save-store.js?v=indexeddb-v1";

function assert_webgl2() {
  const ctx = document.createElement("canvas").getContext("webgl2");
  if (!ctx) {
    throw new Error("webgl2 not supported");
  }
}

function loadMooncraftRuntime() {
  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = "./js/release/build/mooncraft.js?v=indexeddb-v1";
    script.async = true;
    script.onload = () => resolve();
    script.onerror = () => reject(new Error("failed to load Mooncraft runtime"));
    document.head.appendChild(script);
  });
}

function defaultWorldType() {
  const types = globalThis.mcWorldTypes;
  return Array.isArray(types) && typeof types[0] === "string" ? types[0] : "Infinite";
}

function randomWorldSeed() {
  if (typeof globalThis.crypto?.getRandomValues === "function") {
    const value = new Uint32Array(1);
    globalThis.crypto.getRandomValues(value);
    return value[0];
  }
  return Date.now() >>> 0;
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
      saveText: slot.payload,
    };
  }
  return {
    seed: randomWorldSeed(),
    worldType: slot.newWorldType ?? defaultWorldType(),
    saveText: "",
  };
}

async function bootstrap(slot) {
  assert_webgl2();
  const launch = launchRequest(slot);
  window.mcLaunchGame(launch.seed, launch.worldType, launch.saveText);
  const textures = await loadBlockTextures();
  const blockRegistry = createBlockRegistry(textures.textureIndex);
  window.mcBlocks = blockRegistry;
  window.mcTextures = textures;
  const chunkSize = window.mcChunkSize;
  const saveWriter = createSaveWriter(slot.id);
  renderTestChunk({
    blockRegistry,
    textures,
    chunkSize,
    persistSave: (payload) => {
      void saveWriter.enqueue(payload).catch((error) => {
        console.error("[save] failed to write IndexedDB payload", error);
      });
    },
  });
}

async function start() {
  await loadMooncraftRuntime();
  let menu = null;
  menu = await createSaveMenu({
    onOpen: (slot) => {
      menu.remove();
      bootstrap(slot).catch((err) => { console.error(err); });
    },
  });
  document.body.appendChild(menu);
}

start();
