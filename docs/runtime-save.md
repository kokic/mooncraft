# Runtime Save (V2)

## Runtime State Bridge

JS runtime snapshot API:

- `window.mcCaptureRuntimeState()`
- `window.mcApplyRuntimeState(state)`

MoonBit can call the same bridge via `@ffi`:

- `@ffi.runtime_state_snapshot()`
- `@ffi.runtime_state_snapshot_as[T]()`
- `@ffi.apply_runtime_state(value)`

## Local Save

- Default save storage key: `mooncraft.save.v2`
- Active save storage key: `window.mcSelectedSaveStorageKey`, copied into
  `mcSaveStorageKey` during MoonBit bootstrap
- Save registry key: `mooncraft.saves.v1`
- Schema version: `1`

Payload fields:

- `savedAt`
- `world`
  - `seed`
  - `worldType`
  - `saveVersion`
- `runtime`
  - player state
  - hotbar state
  - ui state
- `blockDeltas`
  - edited block records: `wx`, `wy`, `wz`, `id`

## Save Timing

- Throttled auto-save
- `beforeunload` flush

## Save Menu

`dist/js/app-main.js` shows a local save menu before loading
`dist/js/release/build/mooncraft.js`. Opening a save sets
`window.mcSelectedSaveStorageKey`, then loads the MoonBit runtime so world
metadata and renderer saves use the selected slot. Deleting a save removes both
the payload key and its registry entry.
