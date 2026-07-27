# Biome System

11 biomes defined as an enum: Plains, Forest, Mountains, WindsweptHills, Desert, DesertLakes, Beach, River, FrozenRiver, Ocean, DeepOcean.

## Climate Sampling

A `BiomeSample` carries 7 noise-derived float channels (range ~-1..1 after fBM normalization):

| Channel | Octaves | Purpose |
|---|---|---|
| Temperature | 4 | Hot/cold biome separation |
| Humidity | 4 | Wet/dry biome separation |
| Continentalness | 4 | Land-vs-ocean elevation band |
| Erosion | 3 | Terrain smoothing, desert-lake variant selector |
| Weirdness | 4 | Mountain score component |
| Ridge | composite | Inverted folded fBM, drives mountainousness |
| River | 3 (abs) | V-shaped depression for river carving |

All channels use salted Perlin noise with coordinate offsets (ranging from -2111 to +7777) to ensure statistical independence.

Ridge is special: it's `1 - |fBM|` of two offset fields blended 70%/30%, producing high values where the fBM output crosses zero — creating ridge lines in mountain areas.

Ocean biomes in Infinite worlds can be promoted to dry land if a `water_context_factor` falls below 0.28. This factor considers the elevation hint (projected surface height from continentalness, erosion, ridge, weirdness) and terrain ruggedness. This prevents all low-continentalness land from being underwater.

## Biome Selection Thresholds

| Threshold | Values |
|---|---|
| DeepOcean | continental ≤ -0.19 |
| Ocean | continental ≤ -0.12 |
| Beach | continental ≤ -0.05 |
| Mountains | mountain_score > 0.62 AND continental > 0.06 |
| WindsweptHills | mountain_score > 0.50 AND continental > -0.10 AND erosion < 0.02 |
| DesertLakes | temperature > 0.34 AND humidity < -0.03 AND erosion > 0.08 AND continental < 0.28 |
| Desert | temperature > 0.34 AND humidity < -0.03 (not DesertLakes) |
| Forest | humidity > 0.12 |
| Plains | everything else |

The mountain score formula: `ridge * (1.20 - erosion_t * 0.60) + |weirdness| * 0.14 + max(0, continental) * 0.18`, where `erosion_t = clamp01((erosion + 1) * 0.5)`.

## Biome-Dependent Terrain Parameters

Each biome carries:
- **base_offset**: vertical offset from sea level (ranges from -7.5 for Ocean to 4.6 for WindsweptHills)
- **mountain_amp**: strength of mountain ridge uplift (ranges from 4.2 for Plains to 36.0 for Mountains)
- **max_height**: absolute Y ceiling (ranges from 55 for DeepOcean to 280 for Mountains)
- **river_carve**: depth of river V-notch (0 for ocean, 3 for plains, 4 for mountains, 10 for Rivers)

**WIP**: Biome blending at edges is not implemented. Biomes change abruptly at block boundaries with no smooth transition.

**WIP**: Only 11 overworld biomes exist — no caves & cliffs biomes (lush caves, dripstone, meadow, grove, etc.), no nether biomes, no end.
