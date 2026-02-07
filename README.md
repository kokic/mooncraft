
### Screenshot

![carved_pumpkin](./screenshot/carved_pumpkin.jpeg)
![biome_water](./screenshot/biome_water.jpeg)

### Build

```sh
moon build --target-dir ./dist
```

### Run

```sh
miniserve dist --index index.html --port 8089 --media-type image --upload-files assets
```

### World Type

You can switch world type by editing `client.mbt`:

```mbt
let world = @level.World::new(world_type=@level.WorldType::Infinite)
```

Replace `Infinite` with one of:

- `@level.WorldType::Infinite`
- `@level.WorldType::Finite`
- `@level.WorldType::Flat`
- `@level.WorldType::PreClassic`

## Progress

### Implemented

- World types:
  - `Infinite` (multi-biome terrain, oceans, desert lakes, trees)
  - `Finite` (independent terrain profile with lower mountains, biome trees, `nether_spire` placement at world origin)
  - `PreClassic` (pre-classic style terrain/materials, cave/water profile, tree generation enabled)
  - `Flat` (default: `"grass", "dirt", "dirt", "bedrock"`)
- Terrain generation:
  - Biome-driven surface and underground generation
  - Separate logic for `Infinite` / `Finite` / `PreClassic`
  - Ore distribution in modern-style worlds
- Rendering / gameplay core:
  - Chunk generation and meshing pipeline
  - Block selection / raycast and placement
  - Basic lighting and world interaction loop

### Next Steps

- Anything interesting! 
  - We welcome all PRs, even those that do not pertain to the design of Minecraft. 
- Improve biome transition blending near borders (reduce abrupt visual seams)
- Add more structure / feature variety beyond current tree + nether spire coverage
- Continue optimizing chunk update / light update hot paths under frequent block edits
- Expand pre-classic specific content (materials / structure presets) for stronger era identity
