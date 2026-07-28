///|
const ZOMBIE_MODEL_URL : String = "./assets/models/zombie.gltf"

///|
const ZOMBIE_TEXTURE_URL : String = "./assets/images/entity/zombie.png"

///|
const ZOMBIE_RENDER_Y_OFFSET : Double = 1.35

///|
fn zombie_spec() -> MobSpec {
  {
    model_url: ZOMBIE_MODEL_URL,
    texture_url: ZOMBIE_TEXTURE_URL,
    render_y_offset: ZOMBIE_RENDER_Y_OFFSET,
    scale: [1.0, 1.0, 1.0],
    move_speed: 2.25,
    turn_speed: 12.0,
    idle_animation: "none",
    walk_animation: "animation.zombie.walk",
  }
}
