///|
test "mesh builders emit consistent vertex and color counts" {
  let size = 3
  let stone = @block.lookup_by_name("stone").unwrap().internal_id()
  let water = @block.lookup_by_name("water").unwrap().internal_id()
  let torch = @block.lookup_by_name("torch").unwrap().internal_id()
  let data : Array[UInt] = Array::make(size * size * size, stone)
  data[(1 * size + 1) * size + 1] = water
  data[(0 * size + 0) * size + 0] = torch
  let light = Bytes::makei(size * size * size, _ => Int::to_byte(15))
  let mesh = build_chunk_mesh(@block.render_registry, data, light, size)
  let split = build_chunk_mesh_split(@block.render_registry, data, light, size)
  let split_count = split.normal.count +
    split.leaf.count +
    split.water.count +
    split.translucent.count
  @test.assert_eq(split_count, mesh.count)
  let colors = build_chunk_colors(@block.render_registry, data, light, size)
  @test.assert_eq(colors.length(), mesh.count * 4)
  let colors_split = build_chunk_colors_split(
    @block.render_registry, data, light, size,
  )
  @test.assert_eq(
    colors_split.normal.length() +
    colors_split.leaf.length() +
    colors_split.water.length() +
    colors_split.translucent.length(),
    mesh.count * 4,
  )
}

///|
test "padded chunk mesh keeps border air invisible" {
  let size = 2
  let stone = @block.lookup_by_name("stone").unwrap().internal_id()
  let pad = size + 2
  let data : Array[UInt] = Array::make(pad * pad * pad, 0)
  data[(1 * pad + 1) * pad + 1] = stone
  let light = Bytes::makei(pad * pad * pad, _ => Int::to_byte(15))
  let mesh = build_chunk_mesh(@block.render_registry, data, light, size)
  // A single stone block with 2x2x2 padded neighbors: exactly six faces.
  @test.assert_eq(mesh.count, 36)
}
