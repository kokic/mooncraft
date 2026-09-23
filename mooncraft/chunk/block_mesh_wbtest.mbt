///|
test "engine registry preserves game block state and selection metadata" {
  for definition in @block.blocks {
    let id = definition.internal_id()
    let render = @block.render_registry.get_by_internal_id(id).unwrap()
    @test.assert_eq(render.internal_id, id)
    @test.assert_eq(render.block.name, definition.name)
    @test.assert_eq(render.block.state, definition.state)
    @test.assert_eq(render.block.selectable, definition.is_selectable())
    @test.assert_eq(render.block.opacity, definition.opacity)
    @test.assert_eq(render.block.luminance, definition.luminance)
    let engine_boxes = (render.block.collision_boxes)(definition.state)
    let game_boxes = definition.collision_boxes()
    @test.assert_eq(engine_boxes.length(), game_boxes.length())
    for i in 0..<engine_boxes.length() {
      @test.assert_eq(engine_boxes[i].min, game_boxes[i].min)
      @test.assert_eq(engine_boxes[i].max, game_boxes[i].max)
    }
  }
}

///|
test "engine meshes and recoloring agree for every registered block variant" {
  for definition in @block.blocks {
    let data = [definition.internal_id()]
    let light : Bytes = [15]
    let mesh = @mesh.build_chunk_mesh_split(
      @block.render_registry, data, light, 1,
    )
    let colors = @mesh.build_chunk_colors_split(
      @block.render_registry, data, light, 1,
    )
    @test.assert_eq(mesh.normal.colors == colors.normal, true, msg=definition.name)
    @test.assert_eq(mesh.leaf.colors == colors.leaf, true, msg=definition.name)
    @test.assert_eq(mesh.water.colors == colors.water, true, msg=definition.name)
    @test.assert_eq(mesh.translucent.colors == colors.translucent, true, msg=definition.name)
    for bucket in [mesh.normal, mesh.leaf, mesh.water, mesh.translucent] {
      @test.assert_eq(bucket.positions.length(), bucket.count * 3)
      @test.assert_eq(bucket.uvs.length(), bucket.count * 2)
      @test.assert_eq(bucket.colors.length(), bucket.count * 4)
    }
  }
}

///|
test "engine keeps cube culling and game render pass assignments" {
  let registry = @block.render_registry
  let stone = @block.name_to_internal_id("stone")
  let single = @mesh.build_chunk_mesh_split(registry, [stone], [15], 1)
  @test.assert_eq(single.normal.count, 36)
  let solid = @mesh.build_chunk_mesh_split(
    registry,
    Array::make(8, stone),
    Bytes::make(8, 15),
    2,
  )
  @test.assert_eq(solid.normal.count, 144)
  let water = @mesh.build_chunk_mesh_split(
    registry,
    [@block.name_to_internal_id("water")],
    [15],
    1,
  )
  @test.assert_eq(water.normal.count, 0)
  @test.assert_eq(water.water.count > 0, true)
  let air = @mesh.build_chunk_mesh_split(registry, [@schema.AIR_ID], [15], 1)
  @test.assert_eq(
    air.normal.count + air.leaf.count + air.water.count + air.translucent.count,
    0,
  )
}
