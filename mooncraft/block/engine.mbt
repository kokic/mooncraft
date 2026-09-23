///|
/// Resolve game-specific families and materials at the engine boundary.
fn Block::engine_block(self : Block) -> @engine.Block {
  let profile = self.profile()
  let geometry = match self.shape {
    Air => @engine.Geometry::Empty
    Gltf => @engine.Geometry::Gltf
    _ => @engine.Geometry::Procedural
  }
  let render_pass = if self.is_water() {
    @engine.RenderPass::Liquid
  } else if self.material is Material::TintedLeaf {
    @engine.RenderPass::Tinted
  } else if self.alpha_mode is AlphaMode::Translucent {
    @engine.RenderPass::Translucent
  } else {
    @engine.RenderPass::Opaque
  }
  {
    name: self.name,
    state: self.state,
    occlusion_cull: self.occlusion_cull,
    inter_cull: self.inter_cull,
    luminance: self.luminance,
    opacity: self.opacity,
    geometry,
    model: profile.model,
    tint: self.material.tint(),
    render_pass,
    selectable: profile.selectable,
    collision_boxes: profile.collision_boxes,
    raycast_boxes: profile.raycast_boxes,
    outline_boxes: profile.outline_boxes,
  }
}
