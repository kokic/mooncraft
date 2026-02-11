///|
fn ore_noise(
  noise : @util.PerlinNoise,
  wx : Int,
  wy : Int,
  wz : Int,
  freq : Double,
  ox : Double,
  oy : Double,
  oz : Double,
) -> Double {
  noise
  .gen3d(
    wx.to_double() * freq + ox,
    wy.to_double() * freq + oy,
    wz.to_double() * freq + oz,
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
  if is_mountains && wy >= 4 && wy <= 28 {
    let emerald_n = ore_noise(noise, wx, wy, wz, 0.115, 13.0, -7.0, 29.0)
    if emerald_n > 0.82 {
      return emerald_ore
    }
  }
  if wy <= -18 {
    let diamond_n = ore_noise(noise, wx, wy, wz, 0.16, -41.0, 23.0, 17.0)
    if diamond_n > 0.78 {
      return diamond_ore
    }
  }
  if wy <= -12 {
    let redstone_n = ore_noise(noise, wx, wy, wz, 0.145, 71.0, -19.0, -37.0)
    if redstone_n > 0.75 {
      return redstone_ore
    }
  }
  if wy <= -8 {
    let lapis_n = ore_noise(noise, wx, wy, wz, 0.132, -27.0, 11.0, 59.0)
    if lapis_n > 0.8 {
      return lapis_ore
    }
  }
  if wy <= -4 {
    let gold_n = ore_noise(noise, wx, wy, wz, 0.124, 31.0, -53.0, 7.0)
    if gold_n > 0.79 {
      return gold_ore
    }
  }
  if wy <= 12 {
    let iron_n = ore_noise(noise, wx, wy, wz, 0.108, -19.0, 5.0, -11.0)
    if iron_n > 0.71 {
      return iron_ore
    }
  }
  if wy <= 28 {
    let coal_n = ore_noise(noise, wx, wy, wz, 0.096, 43.0, -17.0, 23.0)
    if coal_n > 0.66 {
      return coal_ore
    }
  }
  stone
}
