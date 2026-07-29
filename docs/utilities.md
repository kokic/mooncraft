# Utilities

## Noise & Perlin

The Perlin noise implementation follows the classic Ken Perlin algorithm:
- A 512-entry permutation table (duplicated for wrap-around) seeded from the world seed via a salted hash
- `fade` / `fade2` easing curves for smooth interpolation
- `fast` integer hash for gradient vector lookup
- 2D and 3D `gen` methods producing output in [-1, 1]

`PerlinNoise` wraps `Noise` with optional octave accumulation. `fbm2d` (fractional Brownian motion) chains `gen2d` calls with increasing frequency (lacunarity 2.0) and decreasing amplitude (gain 0.5), normalizing by total amplitude. This is the primary noise primitive for biome sampling and terrain height.

## ID

`pack_long_id(block_id, state)` combines 16-bit block ID (lower) + 16-bit state (upper) into a single `UInt`. This is the integer stored in chunk tile arrays. `unpack_long_id` reverses it.

`AIR_ID` = pack(0, 0) — the sentinel for empty blocks.

## AABB

Simple floating-point `AABB` struct with `min`/`max` fields. Used for collision detection in player movement (checking against block shape boxes) and block placement prevention.

## A\* Pathfinding

A generic A\* search parameterized by `Node` and `Key` types with pluggable functions:
- `key(node)` — map node to a hashable key
- `is_goal(node)` — termination predicate
- `neighbors(node)` — adjacency generator
- `heuristic(node)` — cost-to-go estimate (typically Manhattan)

Used by the mob pathfinding system for entity navigation.

## Color

`rgba("#RRGGBB[AA]")` parses a hex color string into a normalized float quadruple.

## LCG

A linear congruential generator (`seed = 48271 * seed + 57`) used for permutation table construction in the noise system. Not used for gameplay randomness.

## Random

Time-based seed generation using `Date.now()` reinterpreted as a Bits[128] for the ChaCha8 random number generator. Used by tree/cactus height variety and feature placement.

## Shading

- `face_shade_scale(face)`: returns directional shading multiplier — 1.0 (top), 0.62 (bottom), 0.72 (X faces), 0.84 (Z faces). These match Minecraft's lighting model.
- `light_level_scale(light)`: converts 0-15 light to a float: `0.18 + light * 0.82 / 15`. The 0.18 lift base prevents completely dark faces even at light level 0.

## UV

`rect_uv_pixels` and `offset_uv_pixels` compute normalized UV rectangles from pixel coordinates on a texture atlas. Used by the mesh builder to map block face textures.

## Vec2 / Vec3

Generic vector types with arithmetic operators, dot product, cross product, normalization, rotation (2D), and linear interpolation. Used throughout for positions, directions, and physics calculations.

## Pixel

`PIXEL_BLOCK_RATIO = 16` — a Minecraft-style block texture is 16×16 pixels. `pixel_to_block_size` scales pixel coordinates to block-space UV values.

## Sugar / Clamp / Arith / Array

Small utility helpers: `clamp01`, `max0`, `floor_div`, `wrap_position` (for safe array indexing), and `array_join_string`. These reduce boilerplate across the codebase.
