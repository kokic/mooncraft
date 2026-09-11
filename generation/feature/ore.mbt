///|
fn ore_field(noise : @util.PerlinNoise, wx : Int, wy : Int, wz : Int) -> Double {
  noise
  .gen3d(
    wx.to_double() * 0.113 + 13.0,
    wy.to_double() * 0.127 - 7.0,
    wz.to_double() * 0.109 + 29.0,
  )
  .abs()
}

///|
/// Replace stone with ore by layered noise rules (Infinite world).
pub fn pick_stone_ore(
  noise : @util.PerlinNoise,
  wx : Int,
  wy : Int,
  wz : Int,
  is_mountains : Bool,
  stone : UInt,
  coal_ore : UInt,
  iron_ore : UInt,
  gold_ore : UInt,
  redstone_ore : UInt,
  diamond_ore : UInt,
  lapis_ore : UInt,
  emerald_ore : UInt,
) -> UInt {
  guard wy <= 28 else { return stone }
  // Partition one coherent field into rarity bands instead of sampling a
  // separate 3D noise field for every eligible ore at every solid block.
  let sample = ore_field(noise, wx, wy, wz)
  if is_mountains && wy >= 4 && wy <= 28 && sample > 0.82 {
    return emerald_ore
  }
  if wy <= -18 && sample > 0.78 {
    return diamond_ore
  }
  if wy <= -12 && sample > 0.74 {
    return redstone_ore
  }
  if wy <= -8 && sample > 0.71 {
    return lapis_ore
  }
  if wy <= -4 && sample > 0.68 {
    return gold_ore
  }
  if wy <= 12 && sample > 0.65 {
    return iron_ore
  }
  if sample > 0.62 {
    return coal_ore
  }
  stone
}
