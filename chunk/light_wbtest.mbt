///|
/// A sealed stone tunnel crosses both an 8-block section boundary and a
/// 16-block chunk boundary. Complete air columns above it supply real skylight.
fn tunnel_runtime() -> ChunkRuntime {
  let world = @level.World::new(seed=1U, world_type=@level.WorldType::Flat)
  let stone = @block.lookup_by_name("stone").unwrap().internal_id()
  let runtime = ChunkRuntime::new(
    world,
    Array::make(4096, stone),
    render_distance=0,
  )
  ignore(
    runtime.publish_generated_column(
      @level.chunk_column_key_by_chunk_xz(1, 0),
      world.generate_chunk_column(1, 0),
    ),
  )
  runtime.chunk_map[@level.chunk_key_by_chunk_xyz(1, 0, 0)] = Array::make(
    4096, stone,
  )
  runtime.light_cache.update_column(runtime.chunk_map, 1, 0)
  for x in 4..<=20 {
    ignore(runtime.set_block(x, 4, 4, @schema.AIR_ID))
  }
  runtime
}

///|
test "cave light responds to sky openings and torch placement and removal" {
  let runtime = tunnel_runtime()
  ignore(settle_lights(runtime))
  @test.assert_eq(runtime.light_at(8, 4, 4), 0)
  @test.assert_eq(runtime.light_at(16, 4, 4), 0)
  @test.assert_eq(runtime.light_at(8, 20, 4), 15)
  @test.assert_eq(settle_lights(runtime).length(), 0)

  let torch = @block.lookup_by_name("torch").unwrap().internal_id()
  @test.assert_eq(runtime.set_block(14, 4, 4, torch), true)
  ignore(settle_lights(runtime))
  @test.assert_eq(runtime.light_at(14, 4, 4), 14)
  @test.assert_eq(runtime.light_at(16, 4, 4), 12)
  @test.assert_eq(runtime.light_at(8, 4, 4), 8)

  @test.assert_eq(runtime.set_block(14, 4, 4, @schema.AIR_ID), true)
  ignore(settle_lights(runtime))
  @test.assert_eq(runtime.light_at(16, 4, 4), 0)
  for y in 5..<=15 {
    ignore(runtime.set_block(8, y, 4, @schema.AIR_ID))
  }
  ignore(settle_lights(runtime))
  @test.assert_eq(runtime.light_at(8, 4, 4), 15)
  @test.assert_eq(runtime.light_at(16, 4, 4), 7)

  let stone = @block.lookup_by_name("stone").unwrap().internal_id()
  ignore(runtime.set_block(8, 15, 4, stone))
  ignore(settle_lights(runtime))
  @test.assert_eq(runtime.light_at(8, 4, 4), 0)
  @test.assert_eq(runtime.light_at(16, 4, 4), 0)
}

///|
test "mesh neighbor lighting agrees with entity samples across section and chunk edges" {
  let runtime = tunnel_runtime()
  let torch = @block.lookup_by_name("torch").unwrap().internal_id()
  ignore(runtime.set_block(14, 4, 4, torch))
  ignore(settle_lights(runtime))
  for sx in 0..<2 {
    let light = runtime.section_light({
      chunk_key: @level.chunk_key_by_chunk_xyz(0, 0, 0),
      x: sx,
      y: 0,
      z: 0,
    })
    @test.assert_eq(light.length(), 1000)
    // Local x=8 lies just outside this section; its face shading must use
    // the same world cell sampled by an entity at that position.
    @test.assert_eq(
      light[(5 * 10 + 5) * 10 + 9].to_int(),
      runtime.light_at(sx * 8 + 8, 4, 4),
    )
  }
}

///|
test "unloading a neighboring light source darkens the surviving cave" {
  let runtime = tunnel_runtime()
  let torch = @block.lookup_by_name("torch").unwrap().internal_id()
  ignore(runtime.set_block(16, 4, 4, torch))
  ignore(settle_lights(runtime))
  @test.assert_eq(runtime.light_at(15, 4, 4), 13)
  runtime.refresh_desired(0, 0)
  ignore(runtime.evict_undesired())
  ignore(settle_lights(runtime))
  @test.assert_eq(runtime.light_at(15, 4, 4), 0)
  runtime.mark_block_changed(15, 4, 4)
  @test.assert_eq(settle_lights(runtime).length(), 0)
}

///|
fn settle_lights(runtime : ChunkRuntime) -> Array[String] {
  let updated : Array[String] = []
  for _ in 0..<10000 {
    for key in runtime.refresh_lights() {
      updated.push(key)
    }
    if runtime.dirty_lights.length() == 0 &&
      runtime.pending_light_chunks.length() == 0 &&
      runtime.active_light is None {
      return updated
    }
  }
  abort("lighting did not settle")
}

///|
test "an edit during an in-flight solve does not publish obsolete light" {
  let runtime = tunnel_runtime()
  ignore(settle_lights(runtime))
  let torch = @block.lookup_by_name("torch").unwrap().internal_id()
  ignore(runtime.set_block(14, 4, 4, torch))
  let key = @level.chunk_key_by_chunk_xyz(0, 0, 0)
  let job = runtime.light_cache.begin([key])
  ignore(job.advance(1))
  runtime.dirty_lights.clear()
  runtime.active_light = Some((key, job))
  ignore(runtime.set_block(14, 4, 4, @schema.AIR_ID))
  for _ in 0..<1000 {
    ignore(runtime.refresh_lights())
    @test.assert_eq(runtime.light_at(16, 4, 4), 0)
    if runtime.pending_light_chunks.length() == 0 &&
      runtime.active_light is None {
      break
    }
  }
  @test.assert_eq(runtime.active_light is None, true)
  @test.assert_eq(runtime.pending_light_chunks.length(), 0)
}

///|
test "recolor uploads are budgeted and geometry rebuilds supersede them" {
  let runtime = tunnel_runtime()
  ignore(settle_lights(runtime))
  let key = @level.chunk_key_by_chunk_xyz(0, 0, 0)
  for x in 0..<2 {
    for y in 0..<2 {
      for z in 0..<2 {
        ignore(
          runtime.build_mesh_command(@block.render_registry, {
            chunk_key: key,
            x,
            y,
            z,
          }),
        )
      }
    }
  }
  let other_key = @level.chunk_key_by_chunk_xyz(1, 0, 0)
  ignore(
    runtime.build_mesh_command(@block.render_registry, {
      chunk_key: other_key,
      x: 0,
      y: 0,
      z: 0,
    }),
  )
  runtime.dirty_sections.clear()
  let first = runtime.build_recolor_commands(
    @block.render_registry,
    [key, other_key],
    [],
  )
  @test.assert_eq(first.length(), runtime.mesh_budget)
  let remaining = runtime.dirty_colors.values().to_array()[0]
  runtime.mark_section_dirty(
    remaining.chunk_key,
    remaining.x,
    remaining.y,
    remaining.z,
  )
  @test.assert_eq(
    runtime.build_recolor_commands(@block.render_registry, [], []).length(),
    0,
  )
  let rebuilt = runtime.build_mesh_command(@block.render_registry, remaining)
  @test.assert_eq(
    runtime
    .build_recolor_commands(@block.render_registry, [], [rebuilt])
    .length(),
    0,
  )
  @test.assert_eq(runtime.dirty_colors.length(), 0)
}

///|
test "nearby torch changes settle within four frames without fallback meshes" {
  let runtime = tunnel_runtime()
  @test.assert_eq(runtime.take_dirty_sections().length(), 0)
  ignore(settle_lights(runtime))
  let torch = @block.lookup_by_name("torch").unwrap().internal_id()
  for id in [torch, @schema.AIR_ID] {
    ignore(runtime.set_block(14, 4, 4, id))
    @test.assert_eq(runtime.take_dirty_sections().length(), 0)
    for _ in 0..<4 {
      ignore(runtime.refresh_lights())
    }
    @test.assert_eq(
      runtime.light_at(16, 4, 4),
      if id == torch {
        12
      } else {
        0
      },
    )
    for section in runtime.take_dirty_sections() {
      @test.assert_eq(runtime.light_ready(section.chunk_key), true)
    }
    ignore(settle_lights(runtime))
  }
}

///|
test "returning to a height refreshes edits deferred outside the mesh window" {
  let runtime = tunnel_runtime()
  ignore(settle_lights(runtime))
  runtime.refresh_mesh_window(200)
  let torch = @block.lookup_by_name("torch").unwrap().internal_id()
  ignore(runtime.set_block(14, 4, 4, torch))
  ignore(settle_lights(runtime))
  runtime.refresh_mesh_window(4)
  ignore(settle_lights(runtime))
  @test.assert_eq(runtime.light_at(16, 4, 4), 12)
}
