import { loadBlockTextures } from "./block-textures.js";
import { createBlockRegistry } from "./block-registry.js";
import { renderTestChunk } from "./world-renderer.js";
import { createSaveMenu } from "./save-manager.js";

function assert_webgl2() {
  const ctx = document.createElement("canvas").getContext("webgl2");
  if (!ctx) {
    throw new Error("webgl2 not supported");
  }
}

function loadMooncraftRuntime() {
  if (typeof window.mcRuntimeReady === "boolean" && window.mcRuntimeReady) {
    return Promise.resolve();
  }
  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = "./js/release/build/mooncraft.js";
    script.async = true;
    script.onload = () => resolve();
    script.onerror = () => reject(new Error("failed to load Mooncraft runtime"));
    document.head.appendChild(script);
  });
}

async function bootstrap() {
  assert_webgl2();
  await loadMooncraftRuntime();
  window.mcLaunchGame();
  const textures = await loadBlockTextures();
  const blockRegistry = createBlockRegistry(textures.textureIndex);
  
  window.mcBlocks = blockRegistry;
  window.mcTextures = textures;

  const chunkSize = window.mcChunkSize;

  renderTestChunk({
    blockRegistry,
    textures,
    chunkSize,
  });
}

function showSaveMenu() {
  const menu = createSaveMenu({
    onOpen: () => {
      menu.remove();
      bootstrap().catch((err) => {
        console.error(err);
      });
    },
  });
  document.body.appendChild(menu);
}

async function start() {
  await loadMooncraftRuntime();
  showSaveMenu();
}
start();
