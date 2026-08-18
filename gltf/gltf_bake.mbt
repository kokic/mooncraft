///|
/// CPU-side baked static glTF model used by the block mesh builder (route A:
/// glTF geometry is merged into the per-chunk mesh at build time, batched with
/// ordinary block faces instead of drawn per instance).
pub struct GltfBakedPrimitive {
  /// Non-indexed triangle vertices, 3 floats each, in model space.
  positions : Array[Float]
  /// 2 floats per vertex, in [0, 1] texture space.
  uvs : Array[Float]
  /// One dominant-axis face shade per triangle (3 vertices each).
  shades : Array[Float]
  factor_r : Float
  factor_g : Float
  factor_b : Float
  factor_a : Float
  alpha_mode : String
  double_sided : Bool
  /// Axis-aligned bounds of the primitive in model space.
  min_x : Float
  min_y : Float
  min_z : Float
  max_x : Float
  max_y : Float
  max_z : Float
}

///|
pub struct GltfBakedModel {
  primitives : Array[GltfBakedPrimitive]
}

///|
/// Declarative spec mapping a block name to the glTF model used for its shape.
pub struct BlockGltfSpec {
  name : String
  url : String
  fit_in_block : Bool
}

///|
pub fn block_gltf_spec(
  name : String,
  url : String,
  fit_in_block : Bool,
) -> BlockGltfSpec {
  { name, url, fit_in_block }
}

///|
/// Block model registry: the mesh builder looks up baked geometry by block name.
let block_gltf_models : @hashmap.HashMap[String, GltfBakedModel] = @hashmap.HashMap([],
)

///|
pub fn block_gltf_model(name : String) -> GltfBakedModel? {
  block_gltf_models.get(name)
}

///|
fn register_block_gltf_model(name : String, model : GltfBakedModel) -> Unit {
  block_gltf_models[name] = model
}

///|
/// Asynchronously fetch, parse, and bake one glTF model for use as a block
/// shape. `on_done` receives an empty string on success or an error message.
fn load_block_gltf_spec(
  spec : BlockGltfSpec,
  on_done : (String) -> Unit,
) -> Unit {
  fetch_array_buffer(
    absolute_asset_url(spec.url),
    buffer => {
      decode_block_gltf(spec.name, spec.url, buffer, spec.fit_in_block, on_done)
    },
    message => on_done("failed to fetch \{spec.url}: \{message}"),
  )
}

///|
/// Load every declared block glTF model in parallel and invoke `on_done` once
/// all complete: an empty string on success or the first error message.
pub fn load_block_gltf_models(
  specs : Array[BlockGltfSpec],
  on_done : (String) -> Unit,
) -> Unit {
  if specs.length() == 0 {
    on_done("")
    return
  }
  let state = BlockGltfLoadState::{
    remaining: specs.length(),
    error: "",
    on_done,
  }
  for spec in specs {
    load_block_gltf_spec(spec, message => {
      if state.error == "" && message != "" {
        state.error = message
      }
      state.remaining -= 1
      if state.remaining == 0 {
        (state.on_done)(state.error)
      }
    })
  }
}

///|
priv struct BlockGltfLoadState {
  mut remaining : Int
  mut error : String
  on_done : (String) -> Unit
}

///|
fn decode_block_gltf(
  name : String,
  url : String,
  buffer : @ffi.ArrayBuffer,
  fit_in_block : Bool,
  on_done : (String) -> Unit,
) -> Unit {
  let (json_text, glb_bin) = try decode_glb_or_json_text(buffer) catch {
    error => {
      on_done(error.message())
      return
    }
  } noraise {
    result => result
  }
  try @json.parse(json_text) catch {
    error => on_done(error.to_string())
  } noraise {
    root =>
      load_gltf_buffers(
        url,
        root,
        glb_bin,
        buffers => {
          match bake_gltf_model(root, buffers, fit_in_block) {
            Some(model) => {
              register_block_gltf_model(name, model)
              on_done("")
            }
            None => on_done("no drawable triangles in \{url}")
          }
        },
        message => on_done(message),
      )
  }
}

///|
priv struct GltfBakePrimitive {
  positions : @ffi.Float32Array
  uvs : @ffi.Float32Array
  indices : @ffi.Float32Array
  material_index : Int
}

///|
priv struct GltfBakePrimitiveRaw {
  positions : Array[Float]
  uvs : Array[Float]
  shades : Array[Float]
  meta : GltfMaterialMeta
}

///|
fn bake_mesh_primitives(
  root : Json,
  buffers : Array[@ffi.ArrayBuffer?],
  mesh_index : Int,
) -> Array[GltfBakePrimitive] {
  let definitions = json_array(json_field(json_object(root), "meshes"))
  guard definitions.get(mesh_index) is Some(mesh_json) else { [] }
  let primitives : Array[GltfBakePrimitive] = []
  for
    primitive_json in json_array(
      json_field(json_object(mesh_json), "primitives"),
    ) {
    let primitive = json_object(primitive_json)
    guard json_int(json_field(primitive, "mode"), fallback=4) == 4 else {
      continue
    }
    let attributes = json_object(json_field(primitive, "attributes"))
    let position_index = json_int(
      json_field(attributes, "POSITION"),
      fallback=-1,
    )
    guard read_accessor_from(root, buffers, position_index) is Some(positions) else {
      continue
    }
    let uv_index = json_int(json_field(attributes, "TEXCOORD_0"), fallback=-1)
    let uvs = read_accessor_from(root, buffers, uv_index).unwrap_or(
      @ffi.Float32Array::new(0),
    )
    let indices = read_indices_from(
      root,
      buffers,
      json_int(json_field(primitive, "indices"), fallback=-1),
    ).unwrap_or(@ffi.Float32Array::new(0))
    primitives.push(GltfBakePrimitive::{
      positions,
      uvs,
      indices,
      material_index: json_int(json_field(primitive, "material")),
    })
  }
  primitives
}

///|
fn transform_vertex(
  world : @ffi.Float32Array,
  x : Double,
  y : Double,
  z : Double,
) -> Array[Double] {
  let out = [0.0, 0.0, 0.0]
  ignore(@camera.transform_point(out, world, [x, y, z]))
  out
}

///|
fn triangle_shade(
  p0 : Array[Double],
  p1 : Array[Double],
  p2 : Array[Double],
) -> Float {
  let ux = p1[0] - p0[0]
  let uy = p1[1] - p0[1]
  let uz = p1[2] - p0[2]
  let vx = p2[0] - p0[0]
  let vy = p2[1] - p0[1]
  let vz = p2[2] - p0[2]
  let nx = uy * vz - uz * vy
  let ny = uz * vx - ux * vz
  let nz = ux * vy - uy * vx
  let ax = nx.abs()
  let ay = ny.abs()
  let az = nz.abs()
  if az > ax && az > ay {
    if nz < 0.0 {
      @util.face_shade_scale(0, 0, -1)
    } else {
      @util.face_shade_scale(0, 0, 1)
    }
  } else if ax > ay {
    if nx < 0.0 {
      @util.face_shade_scale(-1, 0, 0)
    } else {
      @util.face_shade_scale(1, 0, 0)
    }
  } else if ny < 0.0 {
    @util.face_shade_scale(0, -1, 0)
  } else {
    @util.face_shade_scale(0, 1, 0)
  }
}

///|
/// The three transformed vertices of triangle `t` and their source indices.
fn triangle_vertices(
  world : @ffi.Float32Array,
  positions : Array[Double],
  indices : Array[Double],
  t : Int,
) -> ((Array[Double], Array[Double], Array[Double]), Array[Int]) {
  let v : Array[Int] = [0, 0, 0]
  for k in 0..<3 {
    v[k] = if indices.length() > 0 {
      indices[t * 3 + k].to_int()
    } else {
      t * 3 + k
    }
  }
  let p0 = transform_vertex(
    world,
    positions[v[0] * 3],
    positions[v[0] * 3 + 1],
    positions[v[0] * 3 + 2],
  )
  let p1 = transform_vertex(
    world,
    positions[v[1] * 3],
    positions[v[1] * 3 + 1],
    positions[v[1] * 3 + 2],
  )
  let p2 = transform_vertex(
    world,
    positions[v[2] * 3],
    positions[v[2] * 3 + 1],
    positions[v[2] * 3 + 2],
  )
  ((p0, p1, p2), v)
}

///|
/// Append one baked vertex with its UV and shade.
fn emit_baked_vertex(
  out_positions : Array[Float],
  out_uvs : Array[Float],
  out_shades : Array[Float],
  p : Array[Double],
  uvs : Array[Double],
  vi : Int,
  shade : Float,
) -> Unit {
  out_positions.push(Float::from_double(p[0]))
  out_positions.push(Float::from_double(p[1]))
  out_positions.push(Float::from_double(p[2]))
  if uvs.length() >= (vi + 1) * 2 {
    out_uvs.push(Float::from_double(uvs[vi * 2]))
    out_uvs.push(Float::from_double(uvs[vi * 2 + 1]))
  } else {
    out_uvs.push(0.0F)
    out_uvs.push(0.0F)
  }
  out_shades.push(shade)
}

///|
/// Emit one triangle: the front face, plus the back face when double-sided.
fn emit_baked_triangle(
  out_positions : Array[Float],
  out_uvs : Array[Float],
  out_shades : Array[Float],
  uvs : Array[Double],
  p0 : Array[Double],
  p1 : Array[Double],
  p2 : Array[Double],
  v : Array[Int],
  shade : Float,
  double_sided : Bool,
) -> Unit {
  for k in 0..<3 {
    emit_baked_vertex(
      out_positions,
      out_uvs,
      out_shades,
      [p0, p1, p2][k],
      uvs,
      v[k],
      shade,
    )
  }
  if double_sided {
    for k in 0..<3 {
      emit_baked_vertex(
        out_positions,
        out_uvs,
        out_shades,
        [p2, p1, p0][k],
        uvs,
        v[2 - k],
        shade,
      )
    }
  }
}

///|
fn bake_triangles(
  primitive : GltfBakePrimitive,
  world : @ffi.Float32Array,
  meta : GltfMaterialMeta,
  out : Array[GltfBakePrimitiveRaw],
) -> Unit {
  let positions = primitive.positions.values()
  let uvs = primitive.uvs.values()
  let indices = primitive.indices.values()
  let vertex_count = positions.length() / 3
  let tri_count = if indices.length() > 0 {
    indices.length() / 3
  } else {
    vertex_count / 3
  }
  let out_positions : Array[Float] = []
  let out_uvs : Array[Float] = []
  let out_shades : Array[Float] = []
  for t in 0..<tri_count {
    let ((p0, p1, p2), v) = triangle_vertices(world, positions, indices, t)
    emit_baked_triangle(
      out_positions,
      out_uvs,
      out_shades,
      uvs,
      p0,
      p1,
      p2,
      v,
      triangle_shade(p0, p1, p2),
      meta.double_sided,
    )
  }
  out.push(GltfBakePrimitiveRaw::{
    positions: out_positions,
    uvs: out_uvs,
    shades: out_shades,
    meta,
  })
}

///|
fn compute_node_worlds(
  nodes : Array[GltfNode],
  roots : Array[Int],
) -> Array[@ffi.Float32Array] {
  let locals : Array[@ffi.Float32Array] = nodes.map(node => {
    let matrix = @camera.mat4_create()
    match node.matrix {
      Some(value) => ignore(@camera.mat4_copy(matrix, value))
      None =>
        ignore(
          @camera.mat4_from_trs(
            matrix,
            node.translation,
            node.rotation,
            node.scale,
          ),
        )
    }
    matrix
  })
  let worlds : Array[@ffi.Float32Array] = nodes.map(_ => @camera.mat4_create())
  fn visit(index : Int, parent : @ffi.Float32Array?) -> Unit {
    let world = worlds[index]
    match parent {
      Some(parent_world) =>
        ignore(@camera.mat4_mul(world, parent_world, locals[index]))
      None => ignore(@camera.mat4_copy(world, locals[index]))
    }
    for child in nodes[index].children {
      guard child >= 0 && child < nodes.length() else { continue }
      visit(child, Some(world))
    }
  }
  for root in roots {
    guard root >= 0 && root < nodes.length() else { continue }
    visit(root, None)
  }
  worlds
}

///|
fn compute_bounds(
  raw : Array[GltfBakePrimitiveRaw],
) -> (Array[Float], Array[Float]) {
  let min : Array[Float] = [1.0e30F, 1.0e30F, 1.0e30F]
  let max : Array[Float] = [-1.0e30F, -1.0e30F, -1.0e30F]
  for entry in raw {
    for i in 0..<(entry.positions.length() / 3) {
      let x = entry.positions[i * 3]
      let y = entry.positions[i * 3 + 1]
      let z = entry.positions[i * 3 + 2]
      if x < min[0] {
        min[0] = x
      }
      if y < min[1] {
        min[1] = y
      }
      if z < min[2] {
        min[2] = z
      }
      if x > max[0] {
        max[0] = x
      }
      if y > max[1] {
        max[1] = y
      }
      if z > max[2] {
        max[2] = z
      }
    }
  }
  (min, max)
}

///|
fn finalize_primitive(
  raw : GltfBakePrimitiveRaw,
  scale : Float,
  offset : Array[Float],
) -> GltfBakedPrimitive {
  let positions : Array[Float] = []
  let mut min_x = 1.0e30F
  let mut min_y = 1.0e30F
  let mut min_z = 1.0e30F
  let mut max_x = -1.0e30F
  let mut max_y = -1.0e30F
  let mut max_z = -1.0e30F
  for i in 0..<(raw.positions.length() / 3) {
    let x = (raw.positions[i * 3] + offset[0]) * scale
    let y = (raw.positions[i * 3 + 1] + offset[1]) * scale
    let z = (raw.positions[i * 3 + 2] + offset[2]) * scale
    positions.push(x)
    positions.push(y)
    positions.push(z)
    if x < min_x {
      min_x = x
    }
    if y < min_y {
      min_y = y
    }
    if z < min_z {
      min_z = z
    }
    if x > max_x {
      max_x = x
    }
    if y > max_y {
      max_y = y
    }
    if z > max_z {
      max_z = z
    }
  }
  GltfBakedPrimitive::{
    positions,
    uvs: raw.uvs,
    shades: raw.shades,
    factor_r: raw.meta.factor_r,
    factor_g: raw.meta.factor_g,
    factor_b: raw.meta.factor_b,
    factor_a: raw.meta.factor_a,
    alpha_mode: raw.meta.alpha_mode,
    double_sided: raw.meta.double_sided,
    min_x,
    min_y,
    min_z,
    max_x,
    max_y,
    max_z,
  }
}

///|
fn bake_gltf_model(
  root : Json,
  buffers : Array[@ffi.ArrayBuffer?],
  fit_in_block : Bool,
) -> GltfBakedModel? {
  let nodes = parse_nodes(root)
  let worlds = compute_node_worlds(nodes, parse_roots(root))
  let raw : Array[GltfBakePrimitiveRaw] = []
  for node_index, node in nodes {
    guard node.mesh >= 0 else { continue }
    for primitive in bake_mesh_primitives(root, buffers, node.mesh) {
      bake_triangles(
        primitive,
        worlds[node_index],
        parse_material_meta(root, primitive.material_index),
        raw,
      )
    }
  }
  guard raw.length() > 0 else { None }
  let (scale, offset) = if fit_in_block {
    let (min, max) = compute_bounds(raw)
    let extent_x = max[0] - min[0]
    let extent_y = max[1] - min[1]
    let extent_z = max[2] - min[2]
    let extent = if extent_x >= extent_y && extent_x >= extent_z {
      extent_x
    } else if extent_y >= extent_z {
      extent_y
    } else {
      extent_z
    }
    if extent > 0.000001F {
      (1.0F / extent, [-min[0], -min[1], -min[2]])
    } else {
      (1.0F, [0.0F, 0.0F, 0.0F])
    }
  } else {
    (1.0F, [0.0F, 0.0F, 0.0F])
  }
  Some(GltfBakedModel::{
    primitives: raw.map(entry => finalize_primitive(entry, scale, offset)),
  })
}
