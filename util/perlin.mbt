///|
/// Perlin-noise field — the "improved" algorithm from Ken Perlin (2002).
///
/// The noise value at (x, y [,z]) is computed by:
///
///   1. Find the unit cell that contains the point (floor the coords).
///   2. For each corner of the cell, look up a fixed unit-length gradient
///      via the permutation table, and dot it with the offset from that
///      corner to the point.
///   3. Blend the resulting scalars using `fade2`-weighted `lerp`.
///
/// The result is a C²-continuous pseudo-random scalar field with zero
/// spatial bias and a consistent amplitude in [-√2, √2] (2D) / [-√3, √3] (3D).
///
/// This type bundles the permutation table (`Noise`) with the gradient
/// lookup array (`grad_p`). Multiple `PerlinNoise` instances with different
/// seeds produce uncorrelated noise fields — a property exploited by
/// `TerrainNoiseRouter` to give each climate/cave/aquifer channel its
/// own statistically independent source.
pub struct PerlinNoise {
  base : Noise
  grad_p : Array[Vec3[Double]]
}

///|
/// Construct a `PerlinNoise` from a seed.
///
/// The construction has two phases:
///   1. Create a shuffled permutation table via `Noise::new(seed)`.
///   2. Map each permutation value to one of 12 fixed gradient vectors
///      (see `build_gradients`), producing the gradient array `grad_p`.
///
/// Because the permutation table is seed-dependent and the mapping is
/// deterministic, `PerlinNoise` is a pure function of its seed — same
/// seed, same noise field everywhere.
pub fn PerlinNoise::new(seed? : UInt = @env.now().to_uint()) -> PerlinNoise {
  let base = Noise::new(seed~)
  let grad_p = PerlinNoise::build_gradients(base.permutations)
  PerlinNoise::{ base, grad_p }
}

///|
/// Evaluate the noise field at (x, y [,z]).
///
/// Dispatches to `gen2d` when `z` is omitted and `gen3d` when it is
/// provided. This lets callers use a single uniform API.
pub fn PerlinNoise::gen(
  self : PerlinNoise,
  x : Double,
  y : Double,
  z? : Double,
) -> Double {
  z.map_or_else(() => self.gen2d(x, y), z => self.gen3d(x, y, z))
}

///|
/// 3D dot product of a gradient vector and an offset.
///
///   dot(g, o) = g.x · o.x + g.y · o.y + g.z · o.z
///
/// In 2D the z-component of the offset is always 0.0 and the gradient's
/// z-component is ±1 or 0, so the result still varies.
fn gradient_dot(
  gradient : Vec3[Double],
  x : Double,
  y : Double,
  z : Double,
) -> Double {
  gradient.x * x + gradient.y * y + gradient.z * z
}

///|
/// Evaluate the noise field at a 2D point (x, y).
///
/// Algorithm:
///
/// ```
/// (fx, fy+1)                       (fx+1, fy+1)
///    +----------------------------------+
///    |                                  |
///    |         · P (x, y)               |
///    |    offset = (rx, ry)             |
///    |                                  |
///    +----------------------------------+
/// (fx, fy)                         (fx+1, fy)
/// ```
///
///   1. Grid cell: `fx = floor(x)`, `fy = floor(y)`. The point P lies in
///      cell `(fx, fy)..(fx+1, fy+1)`. Compute the in-cell offset
///      `rx = x - fx`, `ry = y - fy` (both in [0, 1)).
///
///   2. Permute: mask `fx, fy` to 8 bits (`ix, iy`) and hash through
///      the permutation table to select four distinct gradients.
///
///   3. Corner dot products:
///        n00 = grad[ix + perm[iy]]     · (rx,     ry,     0)
///        n01 = grad[ix + perm[iy+1]]   · (rx,     ry-1,   0)
///        n10 = grad[ix + perm[iy] +1]  · (rx-1,   ry,     0)
///        n11 = grad[ix + perm[iy+1]+1] · (rx-1,   ry-1,   0)
///
///   4. Blend: apply `fade2` to `rx, ry` to get `u, v`, then bilinearly
///      interpolate the four dot products:
///        result = lerp(lerp(n00, n10, u), lerp(n01, n11, u), v)
///
/// Boundary continuity:
///   At x = fx+1, the right-cell's n00 and this cell's n10 use the same
///   gradient and offset vectors, so the value matches (C⁰). Because
///   fade2'(0) = fade2'(1) = 0, the derivative also matches (C¹), and
///   fade2''(0) = fade2''(1) = 0 gives C² — no visible grid lines.
pub fn PerlinNoise::gen2d(self : PerlinNoise, x : Double, y : Double) -> Double {
  let fx = x.floor().to_int()
  let fy = y.floor().to_int()
  let rx = x - fx.to_double()
  let ry = y - fy.to_double()
  let ix = fx & 255
  let iy = fy & 255
  let perm = self.base.permutations
  let grad_p = self.grad_p
  let n00 = gradient_dot(grad_p[ix + perm[iy]], rx, ry, 0.0)
  let n01 = gradient_dot(grad_p[ix + perm[iy + 1]], rx, ry - 1.0, 0.0)
  let n10 = gradient_dot(grad_p[ix + perm[iy] + 1], rx - 1.0, ry, 0.0)
  let n11 = gradient_dot(grad_p[ix + perm[iy + 1] + 1], rx - 1.0, ry - 1.0, 0.0)
  let u = Noise::fade2(rx)
  Noise::lerp(
    Noise::lerp(n00, n10, u),
    Noise::lerp(n01, n11, u),
    Noise::fade2(ry),
  )
}

///|
/// Evaluate the noise field at a 3D point (x, y, z).
///
/// This is the 3D analogue of `gen2d`. The unit cell is a cube
/// `(fx,fy,fz)..(fx+1,fy+1,fz+1)`. The algorithm:
///
///   1. Find integer cell origin and in-cell offsets `rx, ry, rz`.
///   2. Hash through the 3-level permutation chain
///      `ix + perm[iy + perm[iz]]` to select eight gradients.
///   3. Compute eight corner dot products with appropriate
///      offset vectors (each corner's offset subtracts 1 on the
///      axes where the corner is the "far" side).
///   4. Trilinearly interpolate using `fade2` on all three axes.
pub fn PerlinNoise::gen3d(
  self : PerlinNoise,
  x : Double,
  y : Double,
  z : Double,
) -> Double {
  let fx = x.floor().to_int()
  let fy = y.floor().to_int()
  let fz = z.floor().to_int()
  let rx = x - fx.to_double()
  let ry = y - fy.to_double()
  let rz = z - fz.to_double()
  let ix = fx & 255
  let iy = fy & 255
  let iz = fz & 255
  let perm = self.base.permutations
  let grad_p = self.grad_p
  let n000 = gradient_dot(grad_p[ix + perm[iy + perm[iz]]], rx, ry, rz)
  let n001 = gradient_dot(
    grad_p[ix + perm[iy + perm[iz + 1]]],
    rx,
    ry,
    rz - 1.0,
  )
  let n010 = gradient_dot(
    grad_p[ix + perm[iy + 1 + perm[iz]]],
    rx,
    ry - 1.0,
    rz,
  )
  let n011 = gradient_dot(
    grad_p[ix + perm[iy + 1 + perm[iz + 1]]],
    rx,
    ry - 1.0,
    rz - 1.0,
  )
  let n100 = gradient_dot(
    grad_p[ix + 1 + perm[iy + perm[iz]]],
    rx - 1.0,
    ry,
    rz,
  )
  let n101 = gradient_dot(
    grad_p[ix + 1 + perm[iy + perm[iz + 1]]],
    rx - 1.0,
    ry,
    rz - 1.0,
  )
  let n110 = gradient_dot(
    grad_p[ix + 1 + perm[iy + 1 + perm[iz]]],
    rx - 1.0,
    ry - 1.0,
    rz,
  )
  let n111 = gradient_dot(
    grad_p[ix + 1 + perm[iy + 1 + perm[iz + 1]]],
    rx - 1.0,
    ry - 1.0,
    rz - 1.0,
  )
  let u = Noise::fade2(rx)
  let v = Noise::fade2(ry)
  let w = Noise::fade2(rz)
  Noise::lerp(
    Noise::lerp(Noise::lerp(n000, n100, u), Noise::lerp(n001, n101, u), w),
    Noise::lerp(Noise::lerp(n010, n110, u), Noise::lerp(n011, n111, u), w),
    v,
  )
}

///|
/// Build the gradient lookup table from a permutation array.
///
/// The 12 gradient vectors are all edge-centre directions of a cube:
///   (±1, ±1,  0),   (±1,  0, ±1),   (0,  ±1, ±1)
///
/// These are the 12 directions (out of the 12 cube edges) that Ken Perlin
/// chose for the improved noise. Critically:
///   • All vectors have the same length √2, so the noise amplitude is
///     seed-independent.
///   • They are evenly distributed — no axis or diagonal is preferred —
///     which gives statistically isotropic output.
///   • 12 is the smallest set that avoids visible grid-aligned artifacts.
///
/// The mapping is `grad_p[i] = grad3[perm[i] % 12]`, so the permutation
/// table's pseudorandom order determines which gradient sits at which
/// lattice index. Because `perm` is length-512 and has every value 0..255
/// twice, the resulting `grad_p` also has length 512 and no index is out
/// of range when the cell-offset (+1) lookups in `gen2d` / `gen3d` fire.
fn PerlinNoise::build_gradients(perm : Array[Int]) -> Array[Vec3[Double]] {
  let grad3 : Array[Vec3[Double]] = [
    Vec3::new(1.0, 1.0, 0.0),
    Vec3::new(-1.0, 1.0, 0.0),
    Vec3::new(1.0, -1.0, 0.0),
    Vec3::new(-1.0, -1.0, 0.0),
    Vec3::new(1.0, 0.0, 1.0),
    Vec3::new(-1.0, 0.0, 1.0),
    Vec3::new(1.0, 0.0, -1.0),
    Vec3::new(-1.0, 0.0, -1.0),
    Vec3::new(0.0, 1.0, 1.0),
    Vec3::new(0.0, -1.0, 1.0),
    Vec3::new(0.0, 1.0, -1.0),
    Vec3::new(0.0, -1.0, -1.0),
  ]
  let grad_p = Array::make(perm.length(), Vec3::new(0.0, 0.0, 0.0))
  for i in 0..<perm.length() {
    grad_p[i] = grad3[perm[i] % 12]
  }
  grad_p
}
