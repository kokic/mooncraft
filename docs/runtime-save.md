# Runtime Save (V2)

## IndexedDB Storage

All persistent browser save data lives in IndexedDB. The database is
`mooncraft` and its `saves` object store is the single source of truth for
save slots and serialized world payloads.

Each record is keyed by its save-slot ID and contains:

- `name` and `createdAt`
- `newWorldType` only while a newly created world has not been saved
- `payload`, the MoonBit-generated V2 save JSON after the first autosave

`dist/js/save-store.js` owns database access. The save menu uses it to list,
create, and delete records; the running game uses its serial writer to persist
new payloads in frame order.

## Payload Schema

MoonBit produces schema version `2`:

- `saved_at`
- `world.seed` and `world.world_type`
- `player`
- `inventory`
- `block_deltas`

The IndexedDB layer validates the V2 envelope before it accepts a write. On
startup, MoonBit independently migrates and verifies that a payload belongs to
the world it is restoring.

## Startup And Save Timing

The save menu opens IndexedDB before creating a game. For an existing record,
the browser parses the saved seed and world type, then passes those values and
the payload text to `window.mcLaunchGame`. For a new record, the browser
generates a seed and passes its selected world type.

MoonBit owns autosave dirtiness and throttling. When it emits a save payload,
the renderer forwards it to the IndexedDB writer. `pagehide` and hidden-page
events enqueue a final snapshot; IndexedDB writes remain serialized so a later
frame cannot overwrite a newer one.
