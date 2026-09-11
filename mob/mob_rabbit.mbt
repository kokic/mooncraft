///|
const RABBIT_MODEL_URL : String = "./assets/models/rabbit.gltf"

///|
const RABBIT_TEXTURE_URL : String = "./assets/images/entity/rabbit_white.png"

///|
pub fn rabbit_spec() -> MobSpec {
  {
    model_url: RABBIT_MODEL_URL,
    texture_url: RABBIT_TEXTURE_URL,
    render_y_offset: 0,
    scale: [4.0, 4.0, 4.0],
    move_speed: 0.0,
    turn_speed: 0.0,
    idle_animation: "none",
    walk_animation: "none",
  }
}
