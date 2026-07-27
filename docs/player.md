# Player System

## Movement

`move_player` accepts a `MoveInput` struct and a yaw angle:

```
MoveInput:
  forward, back, left, right : Bool
  up, down : Bool
  sprint : Bool
  fast : Bool
```

Velocity computation:
- **Horizontal**: forward/back/left/right projected into the world plane via yaw, giving a movement direction vector. Base speed modified by sprint (×2), fast (×2), and water slowdown (×0.45).
- **Vertical**: up/down set a fixed vertical speed. Spectator mode adds vertical component; survival/creative use jump mechanics.

Collision resolution: each axis is swept independently with AABB collision against neighboring block shape boxes. The entity cylinder (radius 0.3, height 1.8) is tested per axis — x-movement, then y, then z. When a collision is detected, the entity stops at the contact point.

Spectator mode bypasses all collision checks.

**WIP**: Jumping uses a constant velocity rather than acceleration-based gravity. Sneaking is not implemented. Swimming (horizontal movement in water) only applies a speed multiplier, not full swim mechanics. Elytra flight, sprint particles, and step-assist are not implemented.

## PlayerRuntime

Owns position, yaw, pitch, speed, entity dimensions, move intent, look intent, and the `PlayerInventoryRuntime`. `tick(delta)`:
1. Integrate accumulated look intents (from mouse input) into yaw/pitch
2. Run movement
3. Return snapshot for the JS renderer

## Inventory

9-slot hotbar where each slot is an optional `HotbarSlot(name, category)`. The inventory snapshot (`PlayerInventorySnapshot`) contains:
- Game mode: "creative", "survival", or "spectator"
- Selected hotbar index
- Hotbar slots array
- Inventory open/closed state

`PlayerInventoryRuntime` wraps a mutable snapshot and returns a new snapshot from each mutation. `collect_hotbar_items` and `collect_inventory_items` produce `UiItemView` arrays: block name + category + texture path — consumed by the JS UI mesh builder.

**WIP**: The creative mode inventory has no item browser. Survival mode has no block-breaking-time mechanic, no health/hunger, no crafting grid, no armor slots. The hotbar slot content is purely the current item name — no stack count, no metadata.

## Block Placement Prevention

`can_place_block` checks whether a candidate block's shape boxes would intersect the player's AABB. If the placed block would clip into the player (e.g., placing a block under your feet while standing), placement is denied.

## Spawn

`compute_spawn_position` finds the topmost non-air block at the predefined spawn chunk coordinate, then positions the player three blocks above it. Spawn yaw and pitch are fixed constants aimed at the demo entity area. Loaded worlds restore the camera orientation from the save.
