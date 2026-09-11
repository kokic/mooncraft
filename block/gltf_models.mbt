///|
/// Declarative block -> glTF model mapping, co-located with the block
/// definitions so the model URL and fit setting stay in MoonBit (SSOT).
/// The `block_gltf_specs` are consumed by `@gltf.load_block_gltf_models`.
pub fn block_gltf_specs() -> Array[@gltf.BlockGltfSpec] {
  [
  // @gltf.block_gltf_spec("zombie", "./assets/models/zombie.gltf", false)
  ]
}
