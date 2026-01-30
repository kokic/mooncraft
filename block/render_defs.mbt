///|
pub struct BlockRenderDef {
  name : String
  id : UInt
  state : UInt
  opacity : Int
  render_type : RenderType
  faces : Faces
}

///|
pub let fallback_texture : String = "missing_tile"

///|
pub struct Faces {
  pos_x : String?
  neg_x : String?
  pos_y : String?
  neg_y : String?
  pos_z : String?
  neg_z : String?
}

///|
pub fn Faces::new(
  pos_x? : String,
  neg_x? : String,
  pos_y? : String,
  neg_y? : String,
  pos_z? : String,
  neg_z? : String,
) -> Faces {
  Faces::{ pos_x, neg_x, pos_y, neg_y, pos_z, neg_z }
}

///|
pub fn Faces::isotropic(all : String) -> Faces {
  Faces::new(
    pos_x=all,
    neg_x=all,
    pos_y=all,
    neg_y=all,
    pos_z=all,
    neg_z=all,
  )
}

///|
pub fn Faces::axial(axial : String, side : String) -> Faces {
  Faces::new(
    pos_x=side,
    neg_x=side,
    pos_y=axial,
    neg_y=axial,
    pos_z=side,
    neg_z=side,
  )
}

///|
pub fn Faces::top_bottom(top : String, bottom : String, side : String) -> Faces {
  Faces::new(
    pos_x=side,
    neg_x=side,
    pos_y=top,
    neg_y=bottom,
    pos_z=side,
    neg_z=side,
  )
}

///|
pub let block_render_defs : Array[BlockRenderDef] = [
  BlockRenderDef::{
    name: "air",
    id: 0,
    state: 0,
    opacity: 0,
    render_type: RenderType::Normal,
    faces: Faces::new(),
  },
  BlockRenderDef::{
    name: "stone",
    id: 1,
    state: 0,
    opacity: 15,
    render_type: RenderType::Normal,
    faces: Faces::isotropic("stone"),
  },
  BlockRenderDef::{
    name: "grass",
    id: 2,
    state: 0,
    opacity: 15,
    render_type: RenderType::Normal,
    faces: Faces::top_bottom(
      "grass_carried",
      "dirt",
      "grass_side_carried",
    ),
  },
  BlockRenderDef::{
    name: "dirt",
    id: 3,
    state: 0,
    opacity: 15,
    render_type: RenderType::Normal,
    faces: Faces::isotropic("dirt"),
  },
  BlockRenderDef::{
    name: "sand",
    id: 4,
    state: 0,
    opacity: 15,
    render_type: RenderType::Normal,
    faces: Faces::isotropic("sand"),
  },
  BlockRenderDef::{
    name: "sandstone",
    id: 5,
    state: 0,
    opacity: 15,
    render_type: RenderType::Normal,
    faces: Faces::top_bottom(
      "sandstone_top",
      "sandstone_bottom",
      "sandstone_normal",
    ),
  },
  BlockRenderDef::{
    name: "bedrock",
    id: 6,
    state: 0,
    opacity: 15,
    render_type: RenderType::Normal,
    faces: Faces::isotropic("bedrock"),
  },
]

///|
pub fn collect_texture_names() -> Array[String] {
  let names : Map[String, Bool] = Map::new()
  names[fallback_texture] = true
  for def in block_render_defs {
    let faces = def.faces
    if faces.pos_x is Some(tex) { names[tex] = true }
    if faces.neg_x is Some(tex) { names[tex] = true }
    if faces.pos_y is Some(tex) { names[tex] = true }
    if faces.neg_y is Some(tex) { names[tex] = true }
    if faces.pos_z is Some(tex) { names[tex] = true }
    if faces.neg_z is Some(tex) { names[tex] = true }
  }
  let out : Array[String] = []
  for entry in names {
    let (name, _) = entry
    out.push(name)
  }
  out
}
