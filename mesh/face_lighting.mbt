///|
priv struct FaceLighting {
  color_scale : Float
  alpha_scale : Float
}

///|
/// Resolve visibility, shading and alpha together, including a transparent chunk-boundary
/// face: the model occlusion rules plus the boundary override.
fn face_lighting(
  chunk : PaddedChunk,
  model : @shape.Model,
  render_info : @shape.FaceSource,
  face : @shape.FaceGeom,
  render_block : @block.RenderBlock,
  x : Int,
  y : Int,
  z : Int,
) -> FaceLighting? {
  let (nx, ny, nz) = face.normal
  let neighbor = chunk.block(x + nx, y + ny, z + nz)
  let visible = (model.face_visible)(render_info, face, @shape.FaceOcclusion::{
    neighbor_occludes: neighbor.block.occlusion_cull,
    same_block_cull: render_block.block.inter_cull &&
    render_block.internal_id == neighbor.internal_id,
  })
  let boundary_transparent = is_chunk_boundary_face(
      x,
      y,
      z,
      nx,
      ny,
      nz,
      chunk.size,
    ) &&
    !render_block.block.occlusion_cull
  guard visible || boundary_transparent else { None }
  let light = chunk.light(x + nx, y + ny, z + nz)
  Some({
    color_scale: face_color_scale(light, nx, ny, nz),
    alpha_scale: if boundary_transparent && !visible { 0.0F } else { 1.0F },
  })
}

///|
/// Face shade combined with the neighbor light level.
fn face_color_scale(light : Int, nx : Int, ny : Int, nz : Int) -> Float {
  @util.face_shade_scale(nx, ny, nz) * @util.light_level_scale(light)
}
