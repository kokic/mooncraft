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

### Section Mesh Commands

Each `ChunkRenderFrame` contains up to `mesh_budget` (8) section mesh commands per tick. Each command packages: center position, padded block data (with neighbor context), light data, and the four-pass mesh output. The JS renderer creates or updates WebGL buffers for each section independently.

Recolor commands update only vertex color buffers without rebuilding geometry — used when lighting changes but block shapes stay the same.

## Block Registry

Created once from block texture name lists and atlas indices. Resolves `RenderBlock` (block definition + per-face texture layer indices) by name or long ID. Used by the mesh builder to look up block properties during face construction.

## Camera

`camera_from_yaw_pitch_into` computes direction and center from position, yaw, and pitch. The JS renderer uses these to build view/projection matrices.

## Matrix Math

Pure MoonBit implementations of 4×4 matrix operations on `Float32Array` wrappers: identity, perspective, orthographic, look-at, multiplication, TRS composition, and point transformation. Available for WebGL interop.

**WIP**: The JS renderer currently computes projection/view matrices directly from yaw/pitch/FOV rather than using the MoonBit matrix functions.

## glTF Entity Pipeline

MoonBit parses `.gltf` and `.glb` files, decodes accessor data, creates shader programs, and builds GPU primitives. JS only provides browser resource loading and the WebGL context. Entity instances track model matrices, animation state, and texture overrides. Draw entries are sorted by material — solid passes first, then blend-sorted transparent passes.

**WIP**: The pipeline handles static mesh nodes and node-TRS animation channels with STEP/LINEAR interpolation. CUBICSPLINE interpolation is downgraded to linear blending. Morph targets and skinning are not supported.

## Shaders

Hand-written vertex and fragment shaders:
- **Leaf shader**: applies biome tint to leaf blocks, with fog distance blending for distance-based atmospheric fading
- **Standard shader**: per-face directional shading (face_shade * light_scale) with texture mapping
- **Water shader**: translucent blue tint with alpha

Fragments are provided as string constants (`GLTF_VS_SOURCE`, `GLTF_FS_SOURCE`) and compiled at runtime.

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

Three compile-time flags control lighting behavior (in `level/light.mbt`):

| Flag | Default | Purpose |
|---|---|---|
| `USE_FIXED_LIGHT` | **true** | Skip all lighting computation. Every block is full brightness (15). |
| `ENABLE_SKY_FLOOD_FILL` | true | When fixed light is off, run skylight propagation. |
| `ENABLE_TORCH_LIGHTING` | true | When fixed light is off, run torchlight propagation. |
| `ENABLE_SMOOTH_LIGHTING` | **false** | Blend neighbor light values (expensive, subtle visual effect). |

**Current state**: Fixed lighting is ON by default, so the full propagation code exists but is not exercised at runtime. The codebase is prepared for toggling to dynamic lighting.

## Algorithm

When `USE_FIXED_LIGHT` is off, `build_world_light` runs on all loaded chunks:

1. **Gather block data**: Reads opacity (0-15) and luminance (0-15) from every loaded chunk into a consolidated 3D grid. Unloaded neighbors are treated as fully opaque.

2. **Skylight propagation** (`ENABLE_SKY_FLOOD_FILL`):
   - Start from the top Y layer: for each XZ column, light enters with value 15, reduced by block opacity. Push non-opaque top cells into a BFS queue.
   - BFS propagates downward and horizontally, reducing light by (block_opacity + 1) per step. A special case preserves full 15 light when moving straight down through transparent blocks.
   - Result: light attenuates as it passes through partial-opacity blocks, creating realistic shadows under overhangs.

3. **Skylight fast path** (when `ENABLE_SKY_FLOOD_FILL` is off):
   - Pure vertical trace per XZ column. Light drops to 0 immediately when a block with opacity ≥ 15 is encountered. Simpler but no horizontal light spread.

4. **Torchlight propagation** (`ENABLE_TORCH_LIGHTING`):
   - Identify all blocks with luminance > 0 (torches, glowstone, lava) and seed a BFS queue.
   - BFS propagates in all 6 directions, attenuating by (block_opacity + 1) per step.
   - Light from multiple sources competes at each cell — the maximum wins.

5. **Final light**: per-voxel `max(skylight, torchlight)`.

6. **Per-chunk output**: For each loaded chunk, extract the interior light values (trimming one-block padding) into a packed byte buffer for the mesh builder.

**WIP**: Fixed lighting is the active path. The full propagation system works but is disabled. Smooth lighting (neighbor interpolation) is implemented but turned off by default.

## Light in Mesh Building

Each face's vertex color in the mesh builder is computed as:
```
face_shade * light_scale * material_tint
```

Where:
- `face_shade`: directional constant (1.0 for top, 0.62 for bottom, 0.72 for X faces, 0.84 for Z faces)
- `light_scale`: `0.18 + light_level * (0.82 / 15)`, where `light_level` is the block's light value (0-15). The 0.18 lift prevents total darkness.
- `material_tint`: biome-dependent color for leaves and water; white for normal blocks.

**WIP**: The light scale formula uses a simple linear ramp, not Minecraft's more complex light curve. Smooth lighting blends are not active.
