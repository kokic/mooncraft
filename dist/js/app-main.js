import { loadBlockTextures } from "./block-textures.js";
import { createBlockRegistry } from "./block-registry.js";
import { renderTestChunk } from "./world-renderer.js";

function assert_webgl2() {
  const ctx = document.createElement("canvas").getContext("webgl2");
  if (!ctx) {
    throw new Error("webgl2 not supported");
  }
}

function waitForGltfApi(timeoutMs = 10000) {
  const start = performance.now();
  return new Promise((resolve) => {
    const tick = () => {
      const api = window.mcGltfEntityApi;
      if (api && typeof api.setAnimation === "function") {
        resolve(api);
        return;
      }
      if (performance.now() - start >= timeoutMs) {
        resolve(null);
        return;
      }
      setTimeout(tick, 50);
    };
    tick();
  });
}

function installEntityAnimationDemo() {
  const state = {
    timer: null,
    running: false,
    entityId: "zombie_0",
  };

  const stop = () => {
    if (state.timer != null) {
      clearInterval(state.timer);
      state.timer = null;
    }
    state.running = false;
  };

  const start = async (entityId = "zombie_0", intervalMs = 1400) => {
    stop();
    const api = await waitForGltfApi();
    if (!api) {
      console.warn("[gltf-demo] api not ready");
      return false;
    }
    state.entityId = entityId;
    const clips = [
      "animation.zombie.walk",
      "animation.zombie.attack",
      "riding",
      "none",
    ];
    let i = 0;
    const playNext = async () => {
      const clip = clips[i % clips.length];
      i += 1;
      const ok = await api.setAnimation(state.entityId, clip);
      if (!ok) {
        console.warn("[gltf-demo] failed to set animation", state.entityId, clip);
      }
    };
    await playNext();
    state.timer = setInterval(() => {
      playNext().catch((err) => console.warn("[gltf-demo] tick failed", err));
    }, Math.max(200, Number(intervalMs) || 1400));
    state.running = true;
    return true;
  };

  window.mcStartEntityAnimationDemo = start;
  window.mcStopEntityAnimationDemo = stop;
  window.mcEntityAnimationDemoState = state;
}

async function bootstrap() {
  assert_webgl2();
  const textures = await loadBlockTextures();
  const blockRegistry = createBlockRegistry(textures.textureIndex);
  
  window.mcBlocks = blockRegistry;
  window.mcTextures = textures;

  const chunkData = window.mcChunkData;
  const chunkSize = window.mcChunkSize;
  const chunkGenerator = window.mcGenChunk;

  renderTestChunk({
    blockRegistry,
    textures,
    chunkData,
    chunkSize,
    chunkGenerator,
  });

  installEntityAnimationDemo();
  if (window.mcAutoEntityAnimationDemo !== false) {
    window.mcStartEntityAnimationDemo("zombie_0", 1500).catch((err) => {
      console.warn("[gltf-demo] auto start failed", err);
    });
  }
}

bootstrap().catch((err) => {
  console.error(err);
});
