///|
test "Perlin optional z dispatches to the matching dimensional sampler" {
  let noise = PerlinNoise::new(seed=17U)
  @test.assert_eq(noise.gen(1.25, -3.5), noise.gen2d(1.25, -3.5))
  @test.assert_eq(noise.gen(1.25, -3.5, z=7.75), noise.gen3d(1.25, -3.5, 7.75))
}
