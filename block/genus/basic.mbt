///|
fn face_layer_default(info : @shape.RenderInfo, face : @shape.FaceName) -> Int {
  match face {
    @shape.FaceName::PosX => info.faces.pos_x
    @shape.FaceName::NegX => info.faces.neg_x
    @shape.FaceName::PosY => info.faces.pos_y
    @shape.FaceName::NegY => info.faces.neg_y
    @shape.FaceName::PosZ => info.faces.pos_z
    @shape.FaceName::NegZ => info.faces.neg_z
  }
}

///|
fn face_box_none(
  _info : @shape.RenderInfo,
  _face : @shape.FaceName,
) -> ((Float, Float, Float), (Float, Float, Float))? {
  None
}

///|
fn uv_rect_default(
  _info : @shape.RenderInfo,
  _face : @shape.FaceName,
) -> (Float, Float, Float, Float) {
  (0.0F, 0.0F, 1.0F, 1.0F)
}

///|
fn rotate_uv_none(_info : @shape.RenderInfo, _face : @shape.FaceGeom) -> Bool {
  false
}

///|
fn double_sided_false(_info : @shape.RenderInfo) -> Bool {
  false
}

///|
fn emit_mesh_none(
  _info : @shape.RenderInfo,
  _bx : Float,
  _by : Float,
  _bz : Float,
  _push_face : @shape.FaceEmitter,
  _push_face_rev : @shape.FaceEmitter,
) -> Bool {
  false
}

///|
fn emit_colors_none(
  _info : @shape.RenderInfo,
  _push_color : @shape.ColorEmitter,
) -> Bool {
  false
}

///|
pub let default_model : @shape.Model = @shape.Model::{
  face_layer: face_layer_default,
  face_box: face_box_none,
  uv_rect: uv_rect_default,
  rotate_uv: rotate_uv_none,
  double_sided: double_sided_false,
  emit_mesh: emit_mesh_none,
  emit_colors: emit_colors_none,
}
