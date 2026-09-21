///|
fn face_layer_default(info : @shape.FaceSource, face : @shape.FaceName) -> Int {
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
  _info : @shape.FaceSource,
  _face : @shape.FaceName,
) -> ((Float, Float, Float), (Float, Float, Float))? {
  None
}

///|
fn uv_rect_default(
  _info : @shape.FaceSource,
  _face : @shape.FaceName,
) -> (Float, Float, Float, Float) {
  (0.0F, 0.0F, 1.0F, 1.0F)
}

///|
fn rotate_uv_none(_info : @shape.FaceSource, _face : @shape.FaceGeom) -> Bool {
  false
}

///|
fn double_sided_false(_info : @shape.FaceSource) -> Bool {
  false
}

///|
let face_boundary_eps : Float = 0.0001F

///|
fn opposite_face_name(face : @shape.FaceName) -> @shape.FaceName {
  match face {
    @shape.FaceName::PosX => @shape.FaceName::NegX
    @shape.FaceName::NegX => @shape.FaceName::PosX
    @shape.FaceName::PosY => @shape.FaceName::NegY
    @shape.FaceName::NegY => @shape.FaceName::PosY
    @shape.FaceName::PosZ => @shape.FaceName::NegZ
    @shape.FaceName::NegZ => @shape.FaceName::PosZ
  }
}

///|
fn face_on_block_boundary(
  face_box : (@shape.FaceSource, @shape.FaceName) -> (
    (Float, Float, Float),
    (Float, Float, Float),
  )?,
  info : @shape.FaceSource,
  face : @shape.FaceName,
) -> Bool {
  match face_box(info, face) {
    None => true
    Some((min, max)) => {
      let (min_x, min_y, min_z) = min
      let (max_x, max_y, max_z) = max
      match face {
        @shape.FaceName::PosX => max_x >= 1.0F - face_boundary_eps
        @shape.FaceName::NegX => min_x <= face_boundary_eps
        @shape.FaceName::PosY => max_y >= 1.0F - face_boundary_eps
        @shape.FaceName::NegY => min_y <= face_boundary_eps
        @shape.FaceName::PosZ => max_z >= 1.0F - face_boundary_eps
        @shape.FaceName::NegZ => min_z <= face_boundary_eps
      }
    }
  }
}

///|
fn face_visible_default(
  face_box : (@shape.FaceSource, @shape.FaceName) -> (
    (Float, Float, Float),
    (Float, Float, Float),
  )?,
  info : @shape.FaceSource,
  face : @shape.FaceGeom,
  occlusion : @shape.FaceOcclusion,
) -> Bool {
  if occlusion.neighbor_occludes {
    false
  } else if occlusion.same_block_cull {
    let self_boundary = face_on_block_boundary(face_box, info, face.name)
    if !self_boundary {
      true
    } else {
      let opposite = opposite_face_name(face.name)
      let other_boundary = face_on_block_boundary(face_box, info, opposite)
      !other_boundary
    }
  } else {
    true
  }
}

///|
fn emit_mesh_none(
  _info : @shape.FaceSource,
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
  _info : @shape.FaceSource,
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
  face_visible: fn(
    info : @shape.FaceSource,
    face : @shape.FaceGeom,
    occlusion : @shape.FaceOcclusion,
  ) {
    face_visible_default(face_box_none, info, face, occlusion)
  },
  emit_mesh: emit_mesh_none,
  emit_colors: emit_colors_none,
}
