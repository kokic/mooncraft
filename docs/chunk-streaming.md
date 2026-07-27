# Chunk Runtime & Streaming

The `ChunkRuntime` owns all CPU-side state for chunk streaming, lighting, mesh invalidation, and block deltas. It produces one `ChunkRenderFrame` per tick — the browser executes these commands but never derives world state independently.

## Chunk Map

An opaque JavaScript `Map` keyed by chunk coordinate strings (format `"cx,cy,cz"`). MoonBit writes tile data arrays (flat `Array[UInt]`) into this map; the JS renderer reads them for mesh building. This is a zero-copy bridge — the same array buffers are visible to both sides.

## Render-Distance Ring Scheduling

`collect_render_column_keys` produces chunk column keys in ring order from the player's position. The ring iteration ensures the closest chunks are generated first, and that the scheduling order matches the JS renderer's expectations.

The desired column set only recalculates when the player's chunk column changes (guarded by `desired_center_x` / `desired_center_z`).

## Column Generation

### Incremental (Infinite Worlds)

Infinite chunk columns are generated across multiple ticks via a state machine:
1. **SampleColumns**: Sample climate + density for each of the 256 XZ blocks
2. **FillColumns**: Apply block palette + ores to all vertical chunks
3. **PlaceTrees**: Run tree placement

Each call to `advance(work_budget)` processes up to `work_budget` units of the current stage. Only one column is in-progress at a time (`active_infinite_column`). Once complete, chunks are published, dirty sections are marked, and lighting is scheduled.

### Synchronous (Finite, PreClassic, Flat Worlds)

`generate_chunk_column` produces all vertical chunks in a single call. Up to `generation_budget` columns are generated per tick.

## Eviction

`evict_undesired` removes columns not in the desired set. Before eviction, it marks boundary sections of loaded neighbors as dirty (forcing remesh of the surfaces adjacent to the evicted column). After eviction, chunk sections, lights, and the chunk map entries are cleaned up.

## Section-Level Meshing

Chunks (16×16×16) are divided into sections (`CHUNK_SECTION_SIZE = 8`) for incremental mesh building. This means a 16³ chunk has 8 sections of 8³ each.

When a block changes, `mark_block_changed` invalidates the section containing the block and all six adjacent sections (since any could expose a new face). The dirty set is processed up to `mesh_budget` sections per tick.

For each dirty section, `section_data` extracts a padded data array (section_size + 2 in each dimension) including neighbor blocks. `build_world_mesh_split` produces four geometry streams (normal, leaf, water, translucent) for the section.

## Block Deltas

All player-induced block changes are stored in a flat `BlockDelta` map (keyed by `"x,y,z"`). When a chunk is generated or reloaded, deltas are overlayed on the procedural data before publishing. This persists edits across chunk eviction/reload cycles and forms the save payload.

## Mesh Commands

Each `ChunkRenderFrame` contains:
- `generated`: new chunk keys published
- `evicted`: chunk keys removed
- `mesh_updates`: section mesh commands (full rebuild of geometry)
- `recolors`: color-only updates for sections that were relit but not remeshed

Recoloring updates only vertex color buffers without rebuilding geometry — essential for lighting changes that don't affect block shapes.
