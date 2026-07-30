///|
priv struct MobSpawn {
  entity_spawn : @entity.EntitySpawn
  render_config : @render.GltfEntityConfig
}

///|
fn resolve_spawn(request : MobSpawnRequest) -> MobSpawn {
  let spec = mob_spec(request.kind)
  let scale = request.scale
  {
    entity_spawn: @entity.EntitySpawn::new(
      request.id,
      Mob(request.kind),
      request.x,
      request.y,
      request.z,
      spec.render_y_offset,
      spec.move_speed,
      spec.turn_speed,
      upside_down=request.upside_down,
      yaw=request.yaw,
    ),
    render_config: @render.entity_config(
      request.id,
      spec.model_url,
      texture=spec.texture_url,
      position=[request.x, request.y + spec.render_y_offset, request.z],
      rotation=mob_rotation(request.yaw, request.upside_down),
      scale~,
      animation=request.animation,
      looped=true,
    ),
  }
}

///|
pub fn spawn(request : MobSpawnRequest) -> Bool {
  let resolved = resolve_spawn(request)
  guard entity_runtime.spawn(resolved.entity_spawn) else { false }
  pending_render_configs.push(resolved.render_config)
  true
}

///|
pub fn restore_entities(saved_entities : Array[@entity.EntitySave]) -> Unit {
  reset_entities()
  entity_runtime.restore_entities(saved_entities)
  for entity in saved_entities {
    match entity.kind {
      Mob(kind) => {
        let spec = mob_spec(kind)
        pending_render_configs.push(
          @render.entity_config(
            entity.id,
            spec.model_url,
            texture=spec.texture_url,
            position=[
              entity.position.x,
              entity.position.y + entity.render_y_offset,
              entity.position.z,
            ],
            rotation=mob_rotation(entity.yaw, entity.upside_down),
            scale=spec.scale,
            animation=spec.idle_animation,
            looped=true,
          ),
        )
      }
      _ => ()
    }
  }
}
