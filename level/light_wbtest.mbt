///|
test "resumed skylight attenuates below water in a sealed shaft" {
  let stone = @block.lookup_by_name("stone").unwrap().internal_id()
  let water = @block.lookup_by_name("water").unwrap().internal_id()
  let data = Array::make(4096, stone)
  for y in 0..<16 {
    data[(y * 16 + 8) * 16 + 8] = @schema.AIR_ID
  }
  data[(15 * 16 + 8) * 16 + 8] = water
  let key = chunk_key_by_chunk_xyz(0, 0, 0)
  let chunks = @hashmap.HashMap([(key, data)])
  let job = WorldLightJob::new(chunks, 16, [key], 0, 15)
  @test.assert_eq(job.advance(0), false)
  @test.assert_eq(job.advance(1), false)
  @test.assert_eq(job.results().length(), 0)
  for _ in 0..<10000 {
    if job.advance(17) {
      break
    }
  }
  @test.assert_eq(job.advance(0), true)
  let (_, light) = job.results()[0]
  @test.assert_eq(light[(16 * 18 + 9) * 18 + 9].to_int(), 13)
  @test.assert_eq(light[(15 * 18 + 9) * 18 + 9].to_int(), 12)
  @test.assert_eq(light[(2 * 18 + 9) * 18 + 9].to_int(), 0)
}

///|
test "source halo includes diagonal negative-coordinate columns" {
  let chunks : @hashmap.HashMap[String, Array[UInt]] = @hashmap.HashMap([])
  let torch = @block.lookup_by_name("torch").unwrap().internal_id()
  let stone = @block.lookup_by_name("stone").unwrap().internal_id()
  for x in -1..<=0 {
    for z in -1..<=0 {
      let data = Array::make(4096, @schema.AIR_ID)
      for i in 3840..<4096 {
        data[i] = stone
      }
      chunks[chunk_key_by_chunk_xyz(x, 0, z)] = data
    }
  }
  chunks[chunk_key_by_chunk_xyz(-1, 0, -1)][(8 * 16 + 15) * 16 + 15] = torch
  let key = chunk_key_by_chunk_xyz(0, 0, 0)
  let result = build_world_light(chunks, 16, [key], 0, 15)
  @test.assert_eq(result.length(), 1)
  let (_, light) = result[0]
  @test.assert_eq(light[(9 * 18 + 1) * 18 + 1].to_int(), 12)
}

///|
test "torch light attenuates vertically while direct sky stays full strength" {
  let stone = @block.lookup_by_name("stone").unwrap().internal_id()
  let torch = @block.lookup_by_name("torch").unwrap().internal_id()
  let chunks : @hashmap.HashMap[String, Array[UInt]] = @hashmap.HashMap([])
  for cy in 0..<3 {
    let data = Array::make(4096, stone)
    for y in 0..<16 {
      data[(y * 16 + 8) * 16 + 8] = @schema.AIR_ID
    }
    chunks[chunk_key_by_chunk_xyz(0, cy, 0)] = data
  }
  let top = chunks[chunk_key_by_chunk_xyz(0, 2, 0)]
  top[(15 * 16 + 8) * 16 + 8] = stone
  top[(8 * 16 + 8) * 16 + 8] = torch
  let cache = LightCache::new(16, 0, 47)
  cache.update_column(chunks, 0, 0)
  let key = chunk_key_by_chunk_xyz(0, 1, 0)
  let job = cache.begin([key])
  while !job.advance(262144) {

  }
  let (_, light) = job.results()[0]
  // Source at y=40: y=31 is nine steps away, y=26 is fourteen.
  @test.assert_eq(light[(16 * 18 + 9) * 18 + 9].to_int(), 5)
  @test.assert_eq(light[(11 * 18 + 9) * 18 + 9].to_int(), 0)
  top[(15 * 16 + 8) * 16 + 8] = @schema.AIR_ID
  top[(8 * 16 + 8) * 16 + 8] = @schema.AIR_ID
  cache.update_column(chunks, 0, 0)
  let sky_job = cache.begin([key])
  while !sky_job.advance(262144) {

  }
  let (_, sky) = sky_job.results()[0]
  @test.assert_eq(sky[(11 * 18 + 9) * 18 + 9].to_int(), 15)
}
