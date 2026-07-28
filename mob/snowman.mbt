///|
const SNOWMAN_MODEL_URL : String = "./assets/models/snowman_on.gltf"

///|
const SNOWMAN_TEXTURE_URL : String = "./assets/images/entity/snowman_face.png"

///|
fn snowman_spec() -> MobSpec {
  {
    model_url: SNOWMAN_MODEL_URL,
    texture_url: SNOWMAN_TEXTURE_URL,
    render_y_offset: -1.05,
    scale: [1.0, 1.0, 1.0],
    move_speed: 0.0,
    turn_speed: 0.0,
    idle_animation: "none",
    walk_animation: "none",
  }
}
