///|
fn generated_oak_tree(seed : UInt) -> Array[(Int, Int, Int, UInt)] {
  let blocks = []
  place_oak_tree_genus(
    (x, y, z, id) => blocks.push((x, y, z, id)),
    12,
    64,
    -8,
    seed~,
  )
  blocks
}

///|
test "oak tree geometry is stable for a world seed and position" {
  @test.assert_eq(generated_oak_tree(23U), generated_oak_tree(23U))
}
