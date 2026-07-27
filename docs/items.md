# Item System

## Definitions

A small compile-time array of `Item` with fields: name, sequentially allocated `ItemId`, texture path, `Category` (Item/Block/None), and `ItemArchetype` (Generic or Tool with kind/tier).

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

Given a wire-format `(name, category)` pair from the browser, the system resolves the target to a known item or block, then dispatches to the archetype-specific behavior. Tools route to their specific action (shovel → grass path conversion, bucket → water removal) or fall through to block placement.

**WIP**: Item definitions are small (4 items). No crafting, no smelting, no item entities (dropped items on the ground), no durability, no enchantments. The bucket can remove water blocks but the water/lava bucket items are not yet hooked up to full fluid placement.

## Species Package

`item/species/` contains `bucket.mbt` and `spawn_egg.mbt` as placeholder notes indicating that species-level behaviors are not yet separated from the main item module due to cyclic import constraints.
