# Generation

## Ore Distribution (Infinite World Only)

Ore selection is a layered rarity system using a single coherent 3D Perlin field sampled once per block. The field value (abs() of the noise) is compared against Y-dependent thresholds from rarest to most common:

| Ore | Y Range | Threshold | Rough Abundance |
|---|---|---|---|
| Emerald | 4..28, Mountains only | > 0.82 | Very rare |
| Diamond | ≤ -18 | > 0.78 | Rare |
| Redstone | ≤ -12 | > 0.74 | Uncommon |
| Lapis | ≤ -8 | > 0.71 | Uncommon |
| Gold | ≤ -4 | > 0.68 | Uncommon |
| Iron | ≤ 12 | > 0.65 | Common |
| Coal | ≤ 28 | > 0.62 | Common |

This approach guarantees a block gets at most one ore type and avoids redundant noise sampling. The field's spatial coherence creates natural-looking vein shapes.

**WIP**: Ore generation exists only in Infinite worlds. Finite and PreClassic use uniform stone. Vein shapes differ from Minecraft's uniform-blob model — this uses continuous noise, which produces smoother, more organic clusters.

---

## Features

### Oak Trees (Infinite, Finite, PreClassic)

`place_oak_tree_genus` selects from three variants:
- **Standard tall**: log trunk + leaf ball with small upper and larger lower canopy
- **Small fancy**: shorter trunk, round canopy
- **Tiny fancy**: 2-3 block trunk with minimal crown

Variants are chosen per-tree using a seed-stable random function. All carry configurable log and leaf fillers.

Placement density follows Minecraft conventions: forest biomes get higher density, plains moderate, others sparse.

`place_fallen_oak_tree` creates horizontal log segments (1-3 length) on the surface.

### Cactus (Infinite Desert Biomes)

Random height 1-4, placed on sand blocks in Desert and DesertLakes biomes. Spacing is seed-stable and prevents immediate adjacency.

### Crop Circles (Infinite Flat Biomes)

Seed-stable large pixel-text messages rendered on the terrain surface using a hand-tuned 5×7 bitmap font. Messages include "Spore", "Herobrine", "Also try Minecraft". Placement is lane-spaced with jitter, determined by a per-line seed.

### Biome Trees (Infinite)

Biome-appropriate trees placed during chunk column generation:
- Forest/Plains → Oak trees at high density
- Mountains/WindsweptHills → Oak trees at medium density
- Desert/DesertLakes → None
- Beach/Ocean/DeepOcean → None
- River → Sparse

Distribution uses a per-block noise threshold: if a block is grass and the random sample crosses the biome threshold, a tree is placed.

---

## Structures

### Nether Spire (Finite World Only)

A 17×35×17 netherrack structure at world origin. The blueprint is defined as ASCII string layers where `N` = netherrack and ` ` = air. Shape: tapering spire with hollow interior, root-like base spreading outward at the bottom.

Placement: centered at (0, surface_height_at_origin, 0). The base extends downward from the surface into the terrain.
