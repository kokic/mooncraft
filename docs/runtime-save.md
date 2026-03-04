# Runtime Save (V1)

## Runtime State Bridge

JS runtime snapshot API:

- `window.mcCaptureRuntimeState()`
- `window.mcApplyRuntimeState(state)`

MoonBit can call the same bridge via `@ffi`:

- `@ffi.runtime_state_snapshot()`
- `@ffi.runtime_state_snapshot_as[T]()`
- `@ffi.apply_runtime_state(value)`

## Local Save

- Save storage key: `mooncraft.save.v1` (`mcSaveStorageKey`)
- Schema version: `1`

Payload fields:

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
