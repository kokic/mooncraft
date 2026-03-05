///|
pub fn demo_entities(world : @level.World) -> Array[@entity.GltfEntityConfig] {
  let entities = zombie_demo_entities(world)

  for entity in rabbit_demo_entities(world) {
    entities.push(entity)
  }

  for entity in snowman_demo_entities(world) {
    entities.push(entity)
  }

  entities
}

///|
pub fn install_default_demo(world : @level.World) -> Unit {
  @entity.publish_entities(demo_entities(world))
  @entity.start_animation_cycle(
    "zombie_0",
    zombie_demo_clips(),
    interval_ms=@entity.DEFAULT_DEMO_INTERVAL_MS,
  )
}
