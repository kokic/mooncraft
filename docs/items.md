# Item System

## Definitions

A small compile-time array of `Item` with fields: name, sequentially allocated `ItemId`, texture path, `Category` (Item/Block/None), and `profile : ItemProfile`. Each `ItemProfile` packs two function pointers (`use_action`, `use_on_action`) — the same pattern as `BlockProfile` in the block package. Named constants (`generic_profile`, `shovel_profile`, `bucket_profile`) let each item declare its behavior at definition time instead of relying on a central dispatch match.

Current items: iron_shovel, bucket, water_bucket, lava_bucket.

## Use Actions

### UseOnAction (right-click on block)

| Action | Description |
|---|---|
| None | No effect |
| ReplaceBlock | Replace target block with a new block if it matches a `BlockSelector` predicate |
| PlaceBlock | Place a named block adjacent to the target, with AABB collision check |
| Batch | Sequence of use-on actions |

### UseAction (left-click / use on self)

| Action | Description |
|---|---|
| None | No effect |
| BreakBlock | Break the targeted block |
| Batch | Sequence of use actions |

### BlockSelector

Matches by exact block name or any-of list.

## Dispatch

Given a wire-format `(name, category)` pair from the browser, the system resolves the target to a known item or block via `UseTarget::from_wire`:
- **KnownItem**: delegates to `Item::use_action()` / `Item::use_on_action()`, each of which calls through to `item.profile.use_action` / `item.profile.use_on_action`.
- **KnownBlock**: block placement (right-click) or block breaking (left-click).
- **Empty** (empty hand): block breaking only.
- **Unknown**: no action.

Each item's profile routes to specific behavior (shovel → grass path conversion, bucket → water removal) or falls through to the generic default.

**WIP**: Item definitions are small (4 items). No crafting, no smelting, no item entities (dropped items on the ground), no durability, no enchantments. The bucket can remove water blocks but the water/lava bucket items are not yet hooked up to full fluid placement.

## Species Package

`item/species/` contains `bucket.mbt` and `spawn_egg.mbt` as placeholder notes. Species-level profile constants are defined alongside the behavior functions in the root `item/` package. Once species sub-packages are wired, they could provide their own `ItemProfile` values without cyclic imports.
