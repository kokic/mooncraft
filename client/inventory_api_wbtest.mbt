///|
test "client inventory views derive from canonical registries" {
  let expected_inventory_count = @block.blocks
    .filter(block => block.category != @item.None)
    .length() +
    @item.items.filter(item => item.category != @item.None).length()
  @test.assert_eq(
    collect_hotbar_items().length(),
    @player.hotbar_blocks.length(),
  )
  @test.assert_eq(collect_inventory_items().length(), expected_inventory_count)
}
