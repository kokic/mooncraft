///|
pub struct RenderBlock {
  name : String
  id : UInt
  state : UInt
  opacity : Int
  render_type : RenderType
  faces : FaceLayers
  long_id : UInt
}

///|
pub struct FaceLayers {
  pos_x : Int
  neg_x : Int
  pos_y : Int
  neg_y : Int
  pos_z : Int
  neg_z : Int
}

///|
pub struct BlockRegistry {
  blocks_by_name : Map[String, RenderBlock]
  blocks_by_long_id : Map[UInt, RenderBlock]
}

///|
pub fn create_block_registry(
  texture_names : Array[String],
  texture_indices : Array[Int],
) -> BlockRegistry {
  let texture_index : Map[String, Int] = Map::new()
  let len = if texture_names.length() < texture_indices.length() {
    texture_names.length()
  } else {
    texture_indices.length()
  }
  for i in 0..<len {
    let name = texture_names[i]
    let index = texture_indices[i]
    if name.length() > 0 {
      texture_index[name] = index
    }
  }
  let blocks_by_name : Map[String, RenderBlock] = Map::new()
  let blocks_by_long_id : Map[UInt, RenderBlock] = Map::new()

  for def in block_render_defs {
    let resolve_layer = fn(tex_name : String?) -> Int {
      match tex_name {
        Some(name) => {
          match texture_index.get(name) {
            Some(v) => v
            None => 0
          }
        }
        None => 0
      }
    }
    let faces = FaceLayers::{
      pos_x: resolve_layer(def.faces.pos_x),
      neg_x: resolve_layer(def.faces.neg_x),
      pos_y: resolve_layer(def.faces.pos_y),
      neg_y: resolve_layer(def.faces.neg_y),
      pos_z: resolve_layer(def.faces.pos_z),
      neg_z: resolve_layer(def.faces.neg_z),
    }
    let long_id = pack_long_id(def.id, def.state)
    let block = RenderBlock::{
      name: def.name,
      id: def.id,
      state: def.state,
      opacity: def.opacity,
      render_type: def.render_type,
      faces,
      long_id,
    }
    blocks_by_name[block.name] = block
    blocks_by_long_id[block.long_id] = block
  }

  BlockRegistry::{ blocks_by_name, blocks_by_long_id }
}

///|
pub fn BlockRegistry::get_by_name(self : BlockRegistry, name : String) -> RenderBlock? {
  self.blocks_by_name.get(name)
}

///|
pub fn BlockRegistry::get_by_long_id(self : BlockRegistry, long_id : UInt) -> RenderBlock? {
  self.blocks_by_long_id.get(long_id)
}
