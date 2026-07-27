# Runtime Save (V2)

## Save Schema

- Default save storage key: `mooncraft.save.v2`
- Save registry key: `mooncraft.saves.v1`
- Schema version: `2`

Payload fields (JSON keys are snake_case):
- `version`, `saved_at`
- `world`: `seed`, `world_type`
- `player`: `position`, `yaw`, `pitch`
- `inventory`: game mode, hotbar items, selection, inventory open state
- `block_deltas`: edited block records with `x`, `y`, `z`, `id`

V1 saves (camelCase keys, nested `runtime` object) are migrated transparently during load.

## Save Flow

On launch, a save menu (`dist/js/save-manager.js`) lets the user select a slot or create a new world. Opening a save sets the active storage key, then loads the MoonBit runtime which reads world metadata from the save payload. During gameplay, state is auto-saved at a throttled cadence, dirtied by block edits, player motion, and inventory changes. On unload, a flush guarantees the latest frame is persisted.
