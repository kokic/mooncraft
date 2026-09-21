///|
test "descending only schedules sections newly entering the mesh window" {
  let world = @level.World::new(seed=1U, world_type=@level.WorldType::Flat)
  let stone = @block.lookup_by_name("stone").unwrap().internal_id()
  let runtime = ChunkRuntime::new(
    world,
    Array::make(4096, stone),
    render_distance=0,
  )
  for data in runtime.chunk_map.values() {
    for i in 0..<data.length() {
      data[i] = stone
    }
  }
  runtime.refresh_mesh_window(8)
  runtime.meshes.dirty_sections.clear()
  runtime.refresh_mesh_window(9)
  @test.assert_eq(runtime.meshes.dirty_sections.length(), 0)
  runtime.refresh_mesh_window(7)
  @test.assert_eq(runtime.meshes.dirty_sections.length(), 4)
  for section in runtime.meshes.dirty_sections.values() {
    let (_, cy, _) = @level.chunk_xyz_by_chunk_key(section.chunk_key)
    @test.assert_eq(cy * 16 + section.y * 8, -48)
  }
}
