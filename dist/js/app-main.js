import { loadBlockTextures } from "./block-textures.js";
import { createBlockRegistry } from "./block-registry.js";
import { renderTestChunk } from "./world-renderer.js";

function assert_webgl2() {
  const ctx = document.createElement("canvas").getContext("webgl2");
  if (!ctx) {
    throw new Error("webgl2 not supported");
  }
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
}

bootstrap().catch((err) => {
  console.error(err);
});
