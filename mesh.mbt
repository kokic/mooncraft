///|
/// Face identifier aligned with axis-aligned cube normals.
enum FaceName {
  /// X+ face (normal = (1, 0, 0))
  PosX
  /// X- face (normal = (-1, 0, 0))
  NegX
  /// Y+ face (normal = (0, 1, 0))
  PosY
  /// Y- face (normal = (0, -1, 0))
  NegY
  /// Z+ face (normal = (0, 0, 1))
  PosZ
  /// Z- face (normal = (0, 0, -1))
  NegZ
}

///|
struct FaceDef {
  name : FaceName
  normal : (Int, Int, Int)
  corners : Array[(Int, Int, Int)]
}

///|
let face_defs : Array[FaceDef] = [
  FaceDef::{
    name: FaceName::PosX,
    normal: (1, 0, 0),
    corners: [(1, 0, 0), (1, 0, 1), (1, 1, 1), (1, 1, 0)],
  },
  FaceDef::{
    name: FaceName::NegX,
    normal: (-1, 0, 0),
    corners: [(0, 0, 1), (0, 0, 0), (0, 1, 0), (0, 1, 1)],
  },
  FaceDef::{
    name: FaceName::PosY,
    normal: (0, 1, 0),
    corners: [(0, 1, 1), (0, 1, 0), (1, 1, 0), (1, 1, 1)],
  },
  FaceDef::{
    name: FaceName::NegY,
    normal: (0, -1, 0),
    corners: [(0, 0, 0), (0, 0, 1), (1, 0, 1), (1, 0, 0)],
  },
  FaceDef::{
    name: FaceName::PosZ,
    normal: (0, 0, 1),
    corners: [(1, 0, 1), (0, 0, 1), (0, 1, 1), (1, 1, 1)],
  },
  FaceDef::{
    name: FaceName::NegZ,
    normal: (0, 0, -1),
    corners: [(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0)],
  },
]

///|
pub struct ChunkEntry {
  x : Int
  y : Int
  z : Int
  data : Array[UInt]
}

///|
pub struct MeshData {
  positions : Array[Float]
  uvs : Array[Float]
  layers : Array[Float]
  count : Int
}

///|
pub fn build_chunk_mesh(
  registry : @block.BlockRegistry,
  chunk_data : Array[UInt],
  size : Int,
) -> MeshData {
  let positions : Array[Float] = []
  let uvs : Array[Float] = []
  let layers : Array[Float] = []
  let zero = Float::from_int(0)
  let one = Float::from_int(1)
  let base_uvs : Array[(Float, Float)] = [
    (zero, zero),
    (one, zero),
    (one, one),
    (zero, zero),
    (one, one),
    (zero, one),
  ]
  let air_block = match registry.get_by_name("air") {
    Some(block) => block
    None => return MeshData::{ positions: [], uvs: [], layers: [], count: 0 }
  }
  let get_index = fn(x : Int, y : Int, z : Int) -> Int {
    (y * size + z) * size + x
  }
  let get_block = fn(x : Int, y : Int, z : Int) -> @block.RenderBlock {
    if x < 0 || x >= size || y < 0 || y >= size || z < 0 || z >= size {
      air_block
    } else {
      let idx = get_index(x, y, z)
      match registry.get_by_long_id(chunk_data[idx]) {
        Some(block) => block
        None => air_block
      }
    }
  }
  for x in 0..<size {
    for y in 0..<size {
      for z in 0..<size {
        let block = get_block(x, y, z)
        if block.name is "air" {
          continue
        }
        for face in face_defs {
          let (nx, ny, nz) = face.normal
          let neighbor = get_block(x + nx, y + ny, z + nz)
          if neighbor.name is "air" {
            let layer = match face.name {
              FaceName::PosX => block.faces.pos_x
              FaceName::NegX => block.faces.neg_x
              FaceName::PosY => block.faces.pos_y
              FaceName::NegY => block.faces.neg_y
              FaceName::PosZ => block.faces.pos_z
              FaceName::NegZ => block.faces.neg_z
            }
            let layer_f = Float::from_int(layer)
            let flip_uv = match face.name {
              FaceName::PosX
              | FaceName::NegX
              | FaceName::PosZ
              | FaceName::NegZ => true
              _ => false
            }
            let a = face.corners[0]
            let b = face.corners[1]
            let c = face.corners[2]
            let d = face.corners[3]
            let (ax, ay, az) = a
            let (bx, by, bz) = b
            let (cx, cy, cz) = c
            let (dx, dy, dz) = d
            let verts : Array[(Int, Int, Int)] = [
              (ax + x, ay + y, az + z),
              (bx + x, by + y, bz + z),
              (cx + x, cy + y, cz + z),
              (ax + x, ay + y, az + z),
              (cx + x, cy + y, cz + z),
              (dx + x, dy + y, dz + z),
            ]
            for i in 0..<6 {
              let (vx, vy, vz) = verts[i]
              positions.push(Float::from_int(vx))
              positions.push(Float::from_int(vy))
              positions.push(Float::from_int(vz))
              let (u, v) = base_uvs[i]
              let v2 = if flip_uv { one - v } else { v }
              uvs.push(u)
              uvs.push(v2)
              layers.push(layer_f)
            }
          }
        }
      }
    }
  }
  MeshData::{ positions, uvs, layers, count: positions.length() / 3 }
}

///|
pub fn build_world_mesh(
  registry : @block.BlockRegistry,
  entries : Array[ChunkEntry],
  size : Int,
) -> MeshData {
  let positions : Array[Float] = []
  let uvs : Array[Float] = []
  let layers : Array[Float] = []
  for entry in entries {
    let mesh = build_chunk_mesh(registry, entry.data, size)
    let offset_x = Float::from_int(entry.x * size)
    let offset_y = Float::from_int(entry.y * size)
    let offset_z = Float::from_int(entry.z * size)
    for i in 0..<mesh.count {
      let pidx = i * 3
      positions.push(mesh.positions[pidx] + offset_x)
      positions.push(mesh.positions[pidx + 1] + offset_y)
      positions.push(mesh.positions[pidx + 2] + offset_z)
      let uidx = i * 2
      uvs.push(mesh.uvs[uidx])
      uvs.push(mesh.uvs[uidx + 1])
      layers.push(mesh.layers[i])
    }
  }
  MeshData::{ positions, uvs, layers, count: positions.length() / 3 }
}
