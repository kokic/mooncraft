///|
pub fn install_default_demo(world : @level.World) -> Unit {
  @render.publish_entities(zombie_demo_entities(world))
  for spawn in zombie_spawns(world) {
    ignore(
      entity_runtime.spawn(
        spawn.id,
        @entity.EntitySpawn::new(
          spawn.position,
          ZOMBIE_RENDER_Y_OFFSET,
          ZOMBIE_MOVE_SPEED,
          ZOMBIE_TURN_SPEED,
        ),
      ),
    )
  }
}
