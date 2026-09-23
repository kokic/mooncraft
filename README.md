
### Screenshot

![carved_pumpkin](./screenshot/carved_pumpkin.jpeg)
![biome_water](./screenshot/biome_water.jpeg)
![snowman](./screenshot/snowman.jpeg)

### Build

```sh
# cd browser && npm install # once
cd browser
npm run build
```

### Run

```sh
cd browser
npm run serve
```

### World Type

The `launchGame` browser entry point selects the world type (`browser/main.mbt`):

```js
launchGame(seed, "Infinite", height, saveText)
```

Supported play-world names:

- `Infinite`
- `Finite`
- `Flat`
- `PreClassic`

## Asset Copyright Notice (Minecraft EULA)

- Files under `browser/web/assets` may contain textures or other resources derived from Minecraft.
- Minecraft and all related assets and intellectual property are owned by Mojang Studios / Microsoft.
- This project is an unofficial fan project and is not affiliated with, endorsed by, or sponsored by Mojang Studios or Microsoft.
- Use and redistribution of these assets must comply with the Minecraft EULA.
- If you plan to publish or commercialize this project, replace `browser/web/assets` resources with original or properly licensed assets.

Reference: https://www.minecraft.net/eula

## Acknowledgments

- Zhuowei Zhang
