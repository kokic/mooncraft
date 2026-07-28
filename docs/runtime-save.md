# Runtime Save (V3)

## IndexedDB Storage

All persistent browser save data lives in IndexedDB. The database is
`mooncraft` and its `saves` object store is the single source of truth for
save slots and serialized world payloads.

Each record is keyed by its save-slot ID and contains:

- `name` and `createdAt`
- `newWorldType` and `newWorldHeight` only while a newly created world has not
  been saved
- `payload`, the MoonBit-generated V3 save JSON after the first save and quit

The IndexedDB schema version is `2`. Its upgrade deletes and recreates the
`saves` object store, intentionally removing every prior browser save. No
legacy slot or payload migration exists.

`dist/js/save-store.js` owns database access. The save menu uses it to list,
create, and delete records; the running game uses its serial writer for the
single explicit save operation.

## Payload Schema

MoonBit produces schema version `3`:

- `saved_at`
- `world.seed`, `world.world_type`, and `world.height`
- `player`
- `inventory`
- `block_deltas`

The IndexedDB layer validates the V3 envelope before it accepts a write.
MoonBit decodes only V3 and verifies seed, type, and height before restoring a
payload.

## Startup And Save Timing

The save menu opens IndexedDB before creating a game. For an existing record,
the browser parses the saved seed, world type, and height, then passes those
values and the payload text to `window.mcLaunchGame`. For a new Infinite
record, the browser passes the selected height; its valid range is `192..384`
and invalid values become `192`.

There is no automatic save. Opening Game Menu and choosing **Save and Quit**
encodes the current state, waits for its IndexedDB write, then disposes the
running session and returns to save selection.
