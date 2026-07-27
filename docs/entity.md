# Entity System

## Types

- **EntitySpawn**: spawn configuration — world position, render Y offset (for model alignment), move speed, turn speed
- **EntitySnapshot**: current state — id, position, yaw, render Y offset. Used to sync with the glTF renderer.
- **EntityEvent**: MovementStarted, WaypointReached, MovementCompleted, MovementCancelled — dispatched to trigger animation changes.

## Movement

`EntityState` holds an optional `MovementPlan` with:
- A list of waypoints (world-space XZ coordinates)
- Index of the next waypoint to approach
- Whether movement has started

`advance(delta)` interpolates position toward the current waypoint:
- Move at `move_speed` (blocks/sec) toward the target XZ
- Turn toward the target at `turn_speed` (radians/sec) using shortest-angle delta
- When within epsilon of the waypoint, advance to the next
- When all waypoints are consumed, emit MovementCompleted

A guard prevents oscillation: waypoints within a small epsilon are considered reached.

## Runtime

`EntityRuntime` holds a map of entity ID → `EntityState`. Each tick advances every entity with an active movement plan, collects events, and returns snapshots for the renderer.

Supported operations: spawn, query position, set path (overwrites any in-progress plan), cancel movement, enumerate current states.

**WIP**: Entities don't have health, damage, death, or despawning. There is no collision detection with blocks or other entities during movement — entities follow their path directly.
