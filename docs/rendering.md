# Rendering System

MoonBit owns all CPU-side rendering work — mesh generation, lighting computation, shader construction, and entity model management. The browser JS layer handles WebGL resource management and draw calls.

## Mesh Building

The primary mesh builder (`build_world_mesh_split`) iterates every block in a section, determines face visibility via neighbor occlusion culling, and emits triangle pairs (6 vertices per face) into interleaved arrays. Rather than one unified mesh, geometry is separated into four render passes:

| Pass | Contents | Shader Behavior |
|---|---|---|
| Normal | Opaque solid blocks (stone, dirt, grass, etc.) | Standard texture + directional shading |
| Leaf | Tinted-leaf material blocks (oak leaves) | Leaf tint shader with fog blending |
| Water | Translucent water blocks | Water shader with blue tint and alpha blending |
| Translucent | Cutout/translucent alpha-mode blocks | Alpha-tested or blended rendering |

This split allows the JS renderer to batch draw calls per pass without per-block state changes. The renderer draws normal and leaf passes first (no depth sorting needed), then water and translucent passes with depth-ordered blending.

### Face Construction

For each visible face of each block:
1. The genus model provides the face AABB, UV coordinates, and texture layer index
2. Vertex positions are computed from the face corners (adjusted for non-cube shapes via genus models)
3. Per-vertex color = `face_shade * light_scale * material_tint`
4. For water blocks, the top face Y is lowered to 15/16 of a block

### glTF Block Models

Blocks with `Shape::Gltf` are baked into the chunk mesh at build time instead of
drawn per instance (route A). The block package declares a `block_gltf_specs`
list (block name, model URL, fit flag); `@gltf.load_block_gltf_models` parses
each model, applies node world transforms, and normalizes geometry. The mesh
builder then merges those triangles into the same `positions/uvs/layers/colors`
buffers as procedural faces, with per-triangle dominant-axis shading, block
light, and material base color folded into the vertex color. The block's
`faces` entry selects the atlas tile the model's UVs sample from. The demo
"zombie" block is baked from `./assets/models/zombie.gltf`.

### Section Mesh Commands

Each `ChunkRenderFrame` contains up to `mesh_budget` (8) section mesh commands per tick. Each command packages: center position, padded block data (with neighbor context), light data, and the four-pass mesh output. The JS renderer creates or updates WebGL buffers for each section independently.

Recolor commands update only vertex color buffers without rebuilding geometry — used when lighting changes but block shapes stay the same.

## Block Registry

Created once from block texture name lists and atlas indices. Resolves `RenderBlock` (block definition + per-face texture layer indices) by name or long ID. Used by the mesh builder to look up block properties during face construction.

Block textures are packed into a single 2D atlas at arbitrary per-tile resolution
(16×16 standard tiles, larger tiles such as the 64×32 zombie skin coexist).
The mesh builder keeps emitting tile-space UVs plus the tile index; the JS
renderer converts them to absolute atlas UVs at upload time, so the GPU samples
the packed atlas with a plain 2D `texture()`.

## Camera

`camera_from_yaw_pitch_into` computes direction and center from position, yaw, and pitch. The JS renderer uses these to build view/projection matrices.

## Matrix Math

Pure MoonBit implementations of 4×4 matrix operations on `Float32Array` wrappers: identity, perspective, orthographic, look-at, multiplication, TRS composition, and point transformation. Available for WebGL interop.

**WIP**: The JS renderer currently computes projection/view matrices directly from yaw/pitch/FOV rather than using the MoonBit matrix functions.

## glTF Entity Pipeline

MoonBit parses `.gltf` and `.glb` files, decodes accessor data, creates shader programs, and builds GPU primitives. JS only provides browser resource loading and the WebGL context. Entity instances track model matrices, animation state, and texture overrides. Draw entries are sorted by material — solid passes first, then blend-sorted transparent passes.

**WIP**: The pipeline handles static mesh nodes and node-TRS animation channels with STEP/LINEAR interpolation. CUBICSPLINE interpolation is downgraded to linear blending. Morph targets and skinning are not supported.

## Shaders

All GLSL sources live in the MoonBit `shader` package: `world.mbt`, `water.mbt`,
`leaf.mbt`, `outline.mbt`, `item.mbt`, and `gltf.mbt`. World, water, and leaves
share the world vertex shader; renderers keep their own attribute and uniform bindings.

`shader/program.mbt` owns shader compilation, program linking, driver errors,
and temporary shader cleanup. Browser renderers import `createProgram` from
`virtual:mooncraft-shader` and select a built-in program by name. The function
returns a WebGL program directly and throws a JS error containing the driver log
on failure. The glTF package uses the same compiler and linker, translating
`ShaderError` into its existing `GltfError` variants.


## UI Mesh

`build_ui_item_mesh` produces a single-block mesh centered at origin for inventory and hotbar item display. Uses a dedicated orthographic projection.

## WebGL FFI

Raw WebGL 2.0 bindings: shader compilation/linking, buffer and VAO lifecycle, texture creation and binding, uniform setters, state management, draw calls, and glTF-specific functions (GLB parsing, accessor reading, primitive building, dispose).

## GPU Resource Lifecycle

- **Chunk meshes**: created per-section, disposed when a section is evicted or recomputed
- **glTF resources**: programs/textures/buffers loaded once per model; instances share resources
- **Block textures**: loaded once at startup into a texture atlas

---

# Lighting System

## Configuration

Four compile-time flags control lighting behavior (in `level/light.mbt`):

| Flag | Default | Purpose |
|---|---|---|
| `USE_FIXED_LIGHT` | **false** | When enabled, skip lighting computation and use full brightness (15). |
| `ENABLE_SKY_FLOOD_FILL` | true | When fixed light is off, run skylight propagation. |
| `ENABLE_TORCH_LIGHTING` | true | When fixed light is off, run torchlight propagation. |
| `ENABLE_SMOOTH_LIGHTING` | **false** | Blend neighbor light values (expensive, subtle visual effect). |

Dynamic lighting is active. `LightCache` stores block opacity, emission and direct skylight for loaded columns. Generation initializes the cache; edits update one voxel and, when opacity changes, its vertical sky shaft. This retains the effect of roofs above the mesh window without rescanning the world height for each solve.

Dirty chunks enter a coalescing queue prioritized by distance to the player in all three axes. Each task solves one output chunk and its one-chunk source halo, including vertical neighbors. Tasks outside the mesh window are deferred until that height enters view. Each frame advances at most 262144 work units, with six units per flood step. Completed chunks publish independently; edits during a solve invalidate stale results.

New or rebuilt meshes wait for their current light map instead of showing fallback lighting. Existing meshes stay visible while replacements are prepared. Recolors share the mesh budget and are superseded by pending geometry rebuilds.

## Algorithm

When `USE_FIXED_LIGHT` is off, `WorldLightJob` advances these phases across frames. `build_world_light` drains the same solver synchronously for callers outside the frame loop:

1. **Gather block data**: Copies cached opacity, emission and direct sky from the local source chunks into byte buffers. Propagation work is independent of total render distance and world height. Unloaded neighbors are treated as fully opaque.

2. **Skylight propagation** (`ENABLE_SKY_FLOOD_FILL`):
   - Start from the top Y layer: for each XZ column, light enters with value 15, reduced by block opacity. First solve direct vertical skylight, then enqueue only cells whose light can spread laterally. Open sky does not fill the BFS queue with redundant cells.
   - BFS propagates downward and horizontally, reducing light by (block_opacity + 1) per step. A special case preserves full 15 light when moving straight down through transparent blocks.
   - Result: light attenuates as it passes through partial-opacity blocks, creating realistic shadows under overhangs.

3. **Skylight fast path** (when `ENABLE_SKY_FLOOD_FILL` is off):
   - Pure vertical trace per XZ column. Light drops to 0 immediately when a block with opacity ≥ 15 is encountered. Simpler but no horizontal light spread.

4. **Torchlight propagation** (`ENABLE_TORCH_LIGHTING`):
   - Identify all blocks with luminance > 0 (torches, glowstone, lava) and seed a BFS queue.
   - BFS propagates in all 6 directions, attenuating by (block_opacity + 1) per step.
   - Light from multiple sources competes at each cell — the maximum wins.

5. **Final light**: per-voxel `max(skylight, torchlight)`.

6. **Per-chunk output**: Each chunk receives a `(size + 2)^3` light buffer. Mesh sections retain the one-block neighbor layer, so faces on section and chunk boundaries sample actual neighboring light.

glTF primitives sample the same combined world light at their transformed centers through `ChunkRuntime::light_at`. Smooth lighting (neighbor interpolation) remains disabled.

## Light in Mesh Building

Each face's vertex color in the mesh builder is computed as:
```
face_shade * light_scale * material_tint
```

Where:
- `face_shade`: directional constant (1.0 for top, 0.62 for bottom, 0.72 for X faces, 0.84 for Z faces)
- `light_scale`: `0.18 + 0.82 * pow(0.9, 15 - light_level)`, shared with glTF entities through `util.light_level_scale`. Level zero remains dimly visible.
- `material_tint`: biome-dependent color for leaves and water; white for normal blocks.

Smooth lighting blends are not active.

The vertical mesh window only schedules sections that newly enter it. Moving within the same section range does not rebuild existing geometry.
