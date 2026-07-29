///|
/// Perlin noise is constructed from three pieces:
///
/// 1. A permutation table — a pseudorandom shuffling of [0..255], duplicated
///    to length 512 so that `perm[i] = perm[i + 256]`. This gives a cheap
///    deterministic hash for lattice-lookup: the gradient index at integer
///    coordinate (ix, iy, iz) is `perm[ix + perm[iy + perm[iz]]]`.
///
/// 2. A fixed set of unit-length gradient vectors (see `build_gradients` in
///    perlin.mbt). The permutation table selects which gradient sits at each
///    lattice vertex. Because the gradients have fixed length, the output
///    amplitude is independent of the seed.
///
/// 3. Interpolation and easing. At a query point (x, y, z) we find its
///    enclosing unit cell, compute the dot product of each corner gradient
///    with the offset from that corner to the point, and blend the four
///    (or eight) scalars with `lerp` and `fade`/`fade2`.
///
/// This file provides the building blocks that `PerlinNoise` (`perlin.mbt`)
/// assembles into the full graded-noise algorithm.
///

/// Standard linear interpolation (affine combination).
///
/// lerp(a, b, t) := (1 - t) · a + t · b
///
/// Properties:
///   • Endpoint match:     t = 0 → a,  t = 1 → b
///   • Convex combination: when t ∈ [0,1] the result lies between a and b
///   • Lowest-degree interpolant (degree 1), i.e. no extra freedom
///   • Used bilinearly (2D) or trilinearly (3D) to blend corner contributions
pub fn Noise::lerp(a : Double, b : Double, t : Double) -> Double {
  (1 - t) * a + t * b
}

/// Smoothstep: f(t) = 3t² - 2t³.
///
/// This is the classic Hermite easing curve. Properties:
///   • f(0) = 0,  f(1) = 1
///   • f'(0) = f'(1) = 0  →  first derivative continuous at cell boundaries
///   • f'(t) = 6·t·(1-t),   i.e. maximum slope at t = 0.5
///
/// Used in finite-difference contexts and as a general-purpose smoother.
/// For Perlin noise itself, `fade2` is preferred because its second
/// derivative also vanishes at the boundaries.
pub fn Noise::fade(t : Double) -> Double {
  t * t * (3 - 2 * t)
}

/// Improved Perlin easing: f(t) = 6t⁵ − 15t⁴ + 10t³.
///
/// This quintic polynomial satisfies:
///   • f(0) = 0,  f(1) = 1
///   • f'(0) = f'(1) = 0   (first derivative vanishes at endpoints)
///   • f''(0) = f''(1) = 0 (second derivative also vanishes)
///   • f'(t) = 30·t²·(t−1)²  →  symmetric, non-negative, zero at both ends
///
/// Vanishing second derivative eliminates the grid-aliasing artifacts that
/// occur with the cubic `fade` — the noise field is C² continuous across
/// cell boundaries instead of just C¹. This is the "improvement" Ken Perlin
/// introduced in his 2002 SIGGRAPH paper.
pub fn Noise::fade2(t : Double) -> Double {
  t * t * t * (t * (t * 6 - 15) + 10)
}

/// Fast integer hash returning a value in [-1, 1].
///
/// Computes a deterministic pseudo-random `Double` from an integer seed
/// using bit-mixing operations (shift-xor-multiply) and maps to the
/// range [-1, 1) via:
///
///   result = 1.0 - (hashed & 0x7fffffff) / 2³⁰
///
/// Properties:
///   • Cheap — only integer arithmetic, no memory access
///   • Deterministic — same input always gives same output
///   • Output range ≈ [-1, 1)
///   • Distribution is approximately uniform
///   • Used for lightweight hashing where quality is less critical
///     than speed (e.g. feature variant selection in tree generation,
///     crop-circle hash01)
pub fn Noise::fast(n : Int) -> Double {
  let n = (n << 13) ^ n
  let n = (n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff
  let d = n.to_double()
  1.0 - d / 1073741824.0
}

/// A noise source defined by a seed and a shuffled permutation table.
///
/// The permutation table is an array of length 512 that contains every
/// value [0..255] exactly twice. This doubling lets us index into it
/// with `ix + perm[iy]` without bounds-checking — because `iy ∈ [0,255]`
/// produces subscripts in [0, 511] and `iy + 1` stays within range.
///
/// The table is generated via the Fisher–Yates shuffle driven by an LCG
/// (linear congruential generator), so it is fully determined by the seed.
pub struct Noise {
  seed : UInt
  permutations : Array[Int]
}

/// Construct a new `Noise` with a shuffled permutation table.
///
/// If no seed is provided, the current system tick (`@env.now`) is used.
/// The LCG-based shuffle guarantees that different seeds produce different,
/// uncorrelated permutation tables.
pub fn Noise::new(seed? : UInt = @env.now().to_uint()) -> Noise {
  let random = LCG(seed~)
  let permutations = Noise::build_permutations(random)
  Noise::{ seed, permutations }
}

/// Fisher–Yates shuffling of [0..255] into an array of length 512.
///
/// Algorithm:
///   1. Fill `perm[0..255]` with identity values.
///   2. Loop `i` from 0 to 255:
///        pick `j` uniformly from `i..256`
///        swap `perm[i]` and `perm[j]`
///        set `perm[i+256] = perm[i]`  (mirror copy)
///
/// The mirror copy ensures that `perm[ix + perm[iy]]` never
/// overflows: when `iy = 255` the lookup `perm[255]` is in [0,255],
/// so `ix + perm[255]` stays ≤ 255 + 255 = 510 < 512. This is what
/// makes the double-width table safe for the gradient-selection
/// pattern in `PerlinNoise::gen2d` / `gen3d`.
fn Noise::build_permutations(random : LCG) -> Array[Int] {
  let perm = Array::make(512, 0)
  for i in 0..<=255 {
    perm[i] = i
  }
  for i in 0..<=255 {
    let modulus = (256 - i).reinterpret_as_uint()
    let j = i + random.next(modulus~).reinterpret_as_int()
    let t = perm[i]
    let v = perm[j]
    perm[i] = v
    perm[i + 256] = v
    perm[j] = t
  }
  perm
}
