///|
test "profile raycast uses cactus bounds" {
  let cactus = lookup_by_name("cactus").unwrap().internal_id()
  let origin = [0.0, 0.5, 0.5]
  let direction = [1.0, 0.0, 0.0]
  @test.assert_eq(
    raycast_intersects(cactus, origin, direction, 0, 0, 0, false),
    true,
  )

  let misses_cactus = raycast_intersects(
    cactus,
    [0.0, 0.5, 0.01],
    direction,
    0,
    0,
    0,
    false,
  )
  @test.assert_eq(misses_cactus, false)
}

///|
test "profile raycast preserves liquid opt-in" {
  let water = lookup_by_name("water").unwrap().internal_id()
  let origin = [0.5, 0.5, -1.0]
  let direction = [0.0, 0.0, 1.0]
  @test.assert_eq(
    raycast_intersects(water, origin, direction, 0, 0, 0, false),
    false,
  )
  @test.assert_eq(
    raycast_intersects(water, origin, direction, 0, 0, 0, true),
    true,
  )
}

///|
test "profile placement preserves torch state" {
  let torch = lookup_by_name("torch").unwrap().internal_id()
  let state = compute_placement_state(torch, [0, 0, 0], [0, 0, 1])
  @test.assert_eq(state, 1U)
}

///|
test "profile outline uses cactus bounds" {
  let cactus = lookup_by_name("cactus").unwrap().internal_id()
  let box = get_outline_desc(cactus).unwrap().boxes[0]
  @test.assert_eq(box.min[0], 0.0625F)
  @test.assert_eq(box.max[0], 0.9375F)
}

///|
test "grass path occludes adjacent cube faces while retaining its lower shape" {
  let grass_path = lookup_by_name("grass_path").unwrap()
  @test.assert_eq(grass_path.occlusion_cull, true)
  let (_, (_max_x, max_y, _max_z)) = @genus.GrassPath::face_box(
    @shape.FaceName::PosY,
  ).unwrap()
  @test.assert_eq(max_y, @genus.GRASS_PATH_MAX_Y)
}

///|
test "slab outline uses half height by state" {
  let slab = lookup_by_name("oak_slab").unwrap()
  let bottom_box = get_outline_desc(slab.internal_id()).unwrap().boxes[0]
  @test.assert_eq(bottom_box.min[1], 0.0F)
  @test.assert_eq(bottom_box.max[1], @genus.SLAB_MAX_Y)
  let top = lookup_by_name("oak_slab:top").unwrap()
  let top_box = get_outline_desc(top.internal_id()).unwrap().boxes[0]
  @test.assert_eq(top_box.min[1], @genus.SLAB_MAX_Y)
  @test.assert_eq(top_box.max[1], 1.0F)
}

///|
test "slab placement picks half from the hit face and click height" {
  let stone_slab = lookup_by_name("stone_slab").unwrap().internal_id()
  // Placing on top of a block (dy = -1 => PosY face) yields the bottom half.
  @test.assert_eq(compute_placement_state(stone_slab, [0, 1, 0], [0, 2, 0]), 0U)
  // Placing against a block's underside (dy = +1 => NegY face) yields the top half.
  @test.assert_eq(compute_placement_state(stone_slab, [0, 2, 0], [0, 1, 0]), 1U)
  // A side face picks the half from the click height.
  @test.assert_eq(
    compute_placement_state(
      stone_slab,
      [0, 1, 0],
      [1, 1, 0],
      click=(0.0, 0.8, 0.5),
    ),
    1U,
  )
  @test.assert_eq(
    compute_placement_state(
      stone_slab,
      [0, 1, 0],
      [1, 1, 0],
      click=(0.0, 0.2, 0.5),
    ),
    0U,
  )
}

///|
test "slab side faces crop the texture to the half height" {
  // Bottom half shows the lower strip of the texture, top half the upper strip.
  let (_, v0_bottom, _, v1_bottom) = @genus.Slab::uv_rect(
    0U,
    @shape.FaceName::PosX,
  )
  @test.assert_eq(v0_bottom, @genus.SLAB_MAX_Y)
  @test.assert_eq(v1_bottom, 1.0F)
  let (_, v0_top, _, v1_top) = @genus.Slab::uv_rect(1U, @shape.FaceName::PosX)
  @test.assert_eq(v0_top, 0.0F)
  @test.assert_eq(v1_top, @genus.SLAB_MAX_Y)
  // Top/bottom faces keep the full texture.
  let (u0, _, u1, _) = @genus.Slab::uv_rect(0U, @shape.FaceName::PosY)
  @test.assert_eq(u0, 0.0F)
  @test.assert_eq(u1, 1.0F)
}

///|
test "slab raycast respects the half height" {
  let slab = lookup_by_name("stone_slab").unwrap().internal_id()
  // A ray above the bottom slab's top face should miss.
  @test.assert_eq(
    raycast_intersects(slab, [0.5, 0.75, -1.0], [0.0, 0.0, 1.0], 0, 0, 0, false),
    false,
  )
  // A ray through the lower half should hit.
  @test.assert_eq(
    raycast_intersects(slab, [0.5, 0.25, -1.0], [0.0, 0.0, 1.0], 0, 0, 0, false),
    true,
  )
}
