# Mob / AI System

## Pathfinding

A standard A\* implementation over a 2D XZ grid with three Y-level candidates per step (current Y, +1, -1). This allows entities to navigate up/down one-block elevation changes.

### Walkability Test

A destination cell (wx, wy, wz) is walkable if:
1. **Floor** (wy - 1) is a solid, non-water, non-air block
2. **Feet** (wy) is passable (air or water)
3. **Head** (wy + 1) is passable (air or water)

Tiles are read from the chunk map via `get_block_id`, not from cached world data, so pathfinding reflects the current world state.

### Heuristic and Limits

- **Heuristic**: Manhattan distance
- **Maximum expansions**: 4096 — pathfinding aborts if the open set empties or exceeds this limit
- Early termination on goal found

**WIP**: The pathfinder is 2D in XZ with only ±1 Y adjustment. It cannot navigate stairs, slabs, or multi-block vertical drops. Water hazards are not avoided — entities path through water cells. There is no height cost penalty, so the shortest 2D path is always chosen regardless of vertical cost.

## AI Tick Loop

`tick_ai(chunk_map, size, delta)` runs per game tick:

1. **Start pending navigation requests**: From the browser (via `mcRequestZombieNavigation`), start A\* searches toward target XZ coordinates.
2. **Advance in-progress searches**: Process at most 96 A\* expansions per tick. Multi-tick amortization prevents frame drops.
3. **Apply found paths**: Push waypoints to the entity runtime when a complete path is found.
4. **Sync entity states**: Bridge entity snapshots (position, yaw) to the glTF renderer. Dispatch animation events:
   - Movement begins → "walk" animation clip
   - Movement completes or is cancelled → "none" clip

## Default Demo

`install_default_demo` spawns four glTF entities:
- **Zombie (standing)**: stationary with idle animation
- **Zombie (riding)**: riding-animated entity next to the standing zombie
- **Snowman**: positioned with face animation
- **Rabbit**: positioned separately

All entities are rendered via the glTF entity pipeline.

**WIP**: Zombie navigation exists (`mcRequestZombieNavigation`) but the demo zombies only move when JS explicitly requests navigation. There is no autonomous AI behavior loop — entities don't wander, flee, or attack on their own.

**WIP**: The A\* pathfinder is the only AI system. There is no behavior tree, no states (idle/patrol/chase/attack), no line-of-sight checks, and no multi-entity coordination.
