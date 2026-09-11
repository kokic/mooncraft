# Block System

## Definitions

Blocks are defined as a flat `Array[Block]` populated at compile time in `definitions.mbt`. Each `Block` carries:

| Field | Purpose |
|---|---|
| UniqueName | String alias (e.g. "grass", "pre-classic.grass") |
| BlockId | Sequentially allocated uint identifier |
| state | Orientation variant word |
| Density | Occlusion opaqueness (0-15) |
| Luminance | Self-emission (0-15, e.g. torches = 15) |
| Opacity | Light-blocking (0-15, max = 15 fully opaque) |
| AlphaMode | Opaque, Cutout, or Translucent |
| Shape | Geometry model selector |
| Facing | Rotation variant generator (None/Axis/Horizontal/Six) |
| Material | Normal, Water, TintedLeaf, or generic Tinted(R,G,B,A) |
| ItemCategory | Block/Item/None — determines whether it appears in the creative inventory |
| Textures | Per-face texture names (top, bottom, front, back, left, right) |

Each `Facing` variant generates multiple block definition entries at compile time with different state values but the same base ID. For example, a `Six`-facing block produces 6 variants (one per direction).

## Shape Model System

The `Shape` enum delegates to a `Model` struct with function pointers:

| Hook | Purpose |
|---|---|
| face_layer | Returns the render layer (normal/water/translucent) and texture face index |
| face_box | Returns the 3D AABB for a given face; cube returns `(0,0,0)-(1,1,1)`, cactus returns inset `(1/16,0,1/16)-(15/16,15/16,15/16)` |
| uv_rect | Returns UV coordinates for a block face |
| rotate_uv | Applies face-rotation (for logs, rotated pillars) |
| double_sided | Returns whether a face renders both sides |
| face_visible | Determines if a face is visible given neighbor block properties |
| emit_mesh | Generates vertex data; torch genus emits custom mesh for mount transforms |
| emit_colors | Generates per-vertex color data |

The default "Cube" model uses standard face occlusion — a face is skipped if the adjacent block is opaque and the same block type. Genus-specific models override one or more hooks.

## Genus Modules

Each genus in `block/genus/` provides the bespoke model for a family of blocks:

- **Log**: Rotates UVs based on axis state, selects end vs side texture layers per face
- **Cactus**: Bounding box inset to 1/16 on all sides, double-sided faces
- **Liquid**: Top Y lowered to 15/16 (water surface sits slightly below the full block), adjusted side UV
- **Torch**: Full custom mesh — wall-mount transforms compute rotation, pivot point, and offset based on placement state
- **Redstone Torch**: Extends torch mesh with an additional glow overlay quad using alpha blend
- **Grass Path**: Top face lowered to 15/16, side faces adjusted UV to compensate
- **Horizontal Facing**: Remaps world-face to source-face for 4-rotation blocks (furnace, dispenser orientation)
- **Six Facing**: Brute-force precomputation of source-face and UV transform tables for all 6×6 state/face combinations at build time, solving orientation and UV roll by exhaustive search
- **Oak Leaves**: Holds the default leaf tint constant
- **Water**: Holds biome-dependent water tint constants and the tint lookup

## Block Placement

`compute_placement_state` determines the state word for a newly placed block:
1. Query the genus-specific placement logic
2. Each genus examines the target block position, the block that was there previously, and optionally the player position
3. For horizontal-facing blocks, the player's position relative to the placed block determines the rotation

**WIP**: Breaking/placing blocks uses a flattened state — all variants of a block share the same display name and item texture. Metadata-specific textures (different wood types, orientation-based icons) are not implemented.

## Material System

Materials drive per-vertex color in the mesh builder:
- **Normal**: White (1,1,1,1) — standard opaque blocks
- **Water**: Blue tinted with alpha 0.62 — used for the water mesh pass
- **TintedLeaf**: Biome-shaded — vertex color is modulated by the leaf tint constant and passed through the leaf shader with fog blending
- **Tinted(R,G,B,A)**: Arbitrary tint for colored blocks

## Lookup

`blocks_by_name` and `blocks_by_long_id` maps are built once at module init. `pack_long_id`/`unpack_long_id` encode 16-bit block ID + 16-bit state into a single uint for tile storage.
