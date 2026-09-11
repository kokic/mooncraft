# Terrain Generation

## World Types

Four world types share a common framework (`World` struct with seed, noise, and type discriminant) but differ radically in generation logic:

| Type | Dimensions | Y Range | Noise Basis | Cave Type | Ore Distribution |
|---|---|---|---|---|---|
| **Infinite** | Unlimited | -64..319 | 20-channel Perlin router | Cheese/Spaghetti/Noodle | Yes |
| **Finite** | 256×128×256 | -64..63 | Single Perlin source | Dual-noise abs-blend | No |
| **PreClassic** | 256×64×256 | -32..31 | Single Perlin source | Dual-noise abs-blend | No |
| **Flat** | Unlimited | -64..319 | None | None | No |

**WIP**: Ore distribution exists only for Infinite worlds. Finite and PreClassic use uniform stone below the surface.

Block column choice is made per-column via `surface_biome_from_column`, which decides surface material (grass/sand/snow) and whether to place trees.

---

## Infinite World: Height Computation

The Infinite world emulates Minecraft 1.18+ overworld terrain. It uses a `TerrainNoiseRouter` — 20 Perlin noise channels with fixed salted seeds — to produce 7 climate channels and 13 density/structure channels.

### Biome Sampling (2D)

`sample_climate` runs fractional Brownian motion (fBM) on 7 climate channels at block-scale world XZ coordinates. Each channel gets 3-4 octaves with lacunarity 2.0 and gain 0.5 for persistence-based detail:

- **Temperature, Humidity, Continentalness, Weirdness**: 4 octaves each.
- **Erosion**: 3 octaves.
- **Ridge**: computed as `1 - |fBM|` from two offset ridge fields (Ridge A at 4 octaves, 70% weight; Ridge B at 3 octaves, 30% weight) to produce a 0..1 inverted-ridge signal most intense in mountain peaks.
- **River**: the absolute value of a 3-octave fBM, producing a V-shaped depression near zero.

### Biome Selection

`biome_from_sample` thresholds the 7 channels hierarchically:

1. **Continentalness** determines marine vs land:
   - ≤ -0.19 → DeepOcean
   - ≤ -0.12 → Ocean
   - ≤ -0.05 → Beach
   - > -0.05 → land (proceed to step 2)
2. **Mountain score** (ridge * (1.20 - erosion * 0.60) + |weirdness| * 0.14 + max(0, continental) * 0.18):
   - > 0.62 → Mountains
   - > 0.50 → WindsweptHills
3. **Temperature + Humidity** for biomes:
   - temp > 0.34 && humidity < -0.03 → Desert (or DesertLakes if erosion > 0.08 and continental < 0.28)
   - humidity > 0.12 → Forest
   - else → Plains

In Infinite worlds, ocean biomes can be overridden to dry land if a `water_context_factor` — combining elevation hint and ruggedness — falls below 0.28. This prevents the entire world from being ocean at low continentalness values.

### Surface Height

`surface_height_with_params` computes per-column surface Y via a multi-stage pipeline:

1. **Plain height** (`plain_height_with_biome`): base height from biome params plus continental lift, erosion penalty, macro hills (fBM at 0.0038 freq, 8.0 amplitude), plains waves at 0.0075 freq with domain-warped coordinates (warp amplitude 28.0), and climate shift. Ocean biomes skip plains waves.

2. **Mountain uplift** (land biomes only): terrain shaping via two ridge fBM signals (0.0078 and 0.016 frequencies) with domain warping (amplitude 42.0). These drive four components blended by `mountain_mask` (smoothstep of the composite mountain signal):
   - **Foothills**: (1 - mask) * biome_amp * (0.11 + ridge_shape * 0.10)
   - **Mountain core**: mask * (ridged_shape² * 0.86 + ridged_shape * 0.14) * biome_amp * (0.50 + (1 - erosion) * 0.82) * biome_uplift
   - **Summit boost**: mask² * biome_amp * (0.06 + ridge_shape * 0.18 + peaks * 0.14) * (0.45 + (1 - erosion) * 0.45) — mountains/windswept only
   - **Jaggedness**: a 0.024-frequency 2D noise modulated by mask blends adds micro-variation

3. **River carving**: `river_t * river_t * river_carve` subtracts from height where the river channel is narrow. Active on Beach biomes; river_carve varies by biome from 0 to 10.

4. **Cap heights**: Beaches are capped ≤ sea_level + 2, Oceans ≤ sea_level - 5, DeepOceans ≤ sea_level - 15.

Final height is clamped to biome-specific max_height.

**WIP**: Biome edge blending is not implemented. Biomes snap at block-level precision with no transition zone.

---

## Caves (Infinite World)

Three cave layers produce distinct void patterns, controlled by `should_carve_cave`:

1. **Cheese caves**: A single 3D Perlin field at frequency 0.028 samples `cave_cheese` noise. If the value exceeds `0.48 + erosion * 0.05`, the block is carved. These produce large, bubble-like caverns.

2. **Spaghetti caves**: Two offset 3D Perlin fields at frequency 0.052, taken as abs(). Both must be below 0.075 simultaneously. These produce long, thin tunnels.

3. **Noodle caves**: Two offset 3D Perlin fields at frequency 0.084, taken as abs(). Both must be below 0.052. These produce very thin, vertical cracks — most common in the deepslate layer.

All cave types are gated by a `cave_region` 3D noise field at frequency 0.009 — only regions where `cave_region > -0.18` can have caves. Caves are also gated by surface clearance (8 blocks minimum for land, 14 for ocean/beach) and minimum Y (world_min_y + 4).

---

## Density Field (Infinite World)

`density_at_column` queries the solid/air field for a block at a specific column and Y:

1. Above `surface + 12` → always air (-1.0).
2. At or below `world_min_y + 1` → always solid (1.0).
3. Otherwise: `terrain_shape_density` computes `vertical_drop + noise_term`, where `noise_term = terrain_shape * (2.8 + ruggedness * 4.2) + ridge_shape * ruggedness * 1.8`. If positive, check for cave carving.

`terrain_shape` is 3D Perlin at 0.021 frequency; `ridge_shape` is a separate 3D field at 0.037. The `ruggedness` factor combines ridge (0.75) and |weirdness| (0.35).

Density is linearly interpolated every 4 vertical blocks to fill the column array, avoiding a full noise query per Y level.

---

## Aquifers (Infinite World)

`aquifer_fluid_at` fills non-solid density regions with water or lava:

1. **Ocean surface**: Blocks above top_solid but ≤ sea_level in Ocean/DeepOcean/Beach biomes → Water.
2. **Lava aquifer**: At Y ≤ `world_min_y + 10`, if a 3D lava barrier noise > -0.32 → Lava. Otherwise air.
3. **Water aquifer**: Above the lava zone, compute a 2D water-level noise (0.012 frequency) offset from `sea_level - 24`. Blocks below this level where a 3D aquifer barrier noise > 0.08 → Water. The barrier creates irregular pockets rather than uniform flooding.

**WIP**: Aquifer fluids do not flow. They are static blocks.

---

## Desert Lakes (Infinite World)

In DesertLakes biomes, `desert_lake_fill_depth` carves basins into the surface:

- Each 32×32 block cell has a random elliptical basin (radii 5-11, depth 4-10).
- Basin center is also noise-jittered within the cell.
- A scaled-ellipse distance formula determines fill depth per position.
- The basin is water-filled, replacing top-surface blocks.

---

## Finite World

The Finite world (256×128×256) uses a simpler generation model:

- **Biome coordinates** are scaled by 1.95 before biome sampling, giving coarser biomes.
- **Surface height** is a simpler formula: `base_height + rolling_fBM + detail_noise + climate_shift + continental_lift`, with biome bonuses for Mountains/WindsweptHills and penalties for Desert/Beach.
- **Caves**: Two offset 3D noise fields (0.041 and 0.068 frequencies) mixed 72%/28%. The blended abs() value must be below a threshold for carving. A separate cave_region field (0.018) gates carving to regions above its threshold.
- **No aquifers, no ores** — blocks below dirt depth are always stone.
- **Nether Spire**: A 17×35×17 blueprint structure made of netherrack at world center (0, surface_y, 0).

---

## PreClassic World

The PreClassic world (256×64×256) emulates old Minecraft terrain:

- **Surface height**: `base_height + rolling_fBM (0.010, 8.0 amp) + detail_noise (0.029, 3.1 amp)`, clamped to -29..29.
- **Water level**: Y -4. Blocks at or below this level above the surface are water.
- **Sand patches**: Near water line, or where a 0.023-frequency noise exceeds 0.66.
- **Caves**: Dual-noise abs-blend (68%/32%) at 0.054 and 0.081 frequencies, with a threshold that loosens with depth below surface (adding 0.0008 per block).
- **Stone block**: Uses `pre-classic.cobblestone` instead of `stone`.
- Oak trees are placed on grass blocks.

---

## Flat World

Stacked layers: grass (top layer at sea level), dirt (3 layers), bedrock (bottom). No noise, no caves, no features.

---

## Incremental Generation (Infinite World)

Infinite worlds generate one chunk column (all vertical chunks for a given XZ) per generation cycle, amortized over multiple ticks:

1. **SampleColumns**: Sample climate and density for all 256 block columns in the XZ chunk column.
2. **FillColumns**: Apply the Infinite block palette (bedrock → stone/deepslate → dirt → grass/sand/snow; with ore replacement) to all vertical chunks.
3. **PlaceTrees**: Place biome-appropriate trees on grass blocks.

Each stage advances a bounded number of work units per tick. The generation object persists across calls until Completed.

**WIP**: Tree placement runs synchronously in the last stage — on large forests this can cause a frame spike.
