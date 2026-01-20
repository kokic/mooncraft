///|
pub struct Vec3[T] {
  x : T
  y : T
  z : T
} derive(Show)

///|
pub fn[T] Vec3::new(x : T, y : T, z : T) -> Vec3[T] {
  Vec3::{ x, y, z }
}

///|
pub impl[T : Add] Add for Vec3[T] with add(u : Vec3[T], v : Vec3[T]) -> Vec3[T] {
  Vec3::new(u.x + v.x, u.y + v.y, u.z + v.z)
}

///|
pub impl[T : Sub] Sub for Vec3[T] with sub(u : Vec3[T], v : Vec3[T]) -> Vec3[T] {
  Vec3::new(u.x - v.x, u.y - v.y, u.z - v.z)
}

///|
pub impl[T : Neg] Neg for Vec3[T] with neg(u) {
  Vec3::new(-u.x, -u.y, -u.z)
}

///|
pub fn[T : Mul] Vec3::scale(v : Vec3[T], s : T) -> Vec3[T] {
  Vec3::new(s * v.x, s * v.y, s * v.z)
}

///|
pub fn[T : Mul + Add] Vec3::dot(u : Vec3[T], v : Vec3[T]) -> T {
  u.x * v.x + u.y * v.y + u.z * v.z
}

///|
pub impl[T : Mul] Mul for Vec3[T] with mul(u : Vec3[T], v : Vec3[T]) -> Vec3[T] {
  Vec3::new(u.x * v.x, u.y * v.y, u.z * v.z)
}

///|
/// ```plain
/// | i   j   k |
/// |u.x u.y u.z|
/// |v.x v.y v.z|
/// ```
pub fn[T : Mul + Sub] Vec3::cross(u : Vec3[T], v : Vec3[T]) -> Vec3[T] {
  // Vec3::new(u.y * v.z - u.z * v.y, u.z * v.x - u.x * v.z, u.x * v.y - u.y * v.x)
  Vec3::new(
    det2(u.y, u.z, v.y, v.z),
    det2(u.z, u.x, v.z, v.x),
    det2(u.x, u.y, v.x, v.y),
  )
}

///|
pub type FVec3 = Vec3[Float]

///|
#alias(norm)
pub fn FVec3::eulidian_norm(v : FVec3) -> Float {
  (v.x * v.x + v.y * v.y + v.z * v.z).sqrt()
}

///|
pub fn FVec3::normalize(v : FVec3) -> FVec3? {
  let norm = FVec3::eulidian_norm(v)
  guard norm != 0.0 else { return None }
  Some(FVec3::scale(v, 1.0 / norm))
}

///|
pub fn FVec3::rotate_x(v : FVec3, angle_rad : Float) -> FVec3 {
  let cos_a = Float::from_double(@math.cos(angle_rad.to_double()))
  let sin_a = Float::from_double(@math.sin(angle_rad.to_double()))
  FVec3::new(
    v.x, //
    v.y * cos_a - v.z * sin_a,
    v.y * sin_a + v.z * cos_a,
  )
}

///|
pub fn FVec3::rotate_y(v : FVec3, angle_rad : Float) -> FVec3 {
  let cos_a = Float::from_double(@math.cos(angle_rad.to_double()))
  let sin_a = Float::from_double(@math.sin(angle_rad.to_double()))
  FVec3::new(
    v.z * sin_a - v.x * cos_a,
    v.y, //
    v.z * cos_a + v.x * sin_a,
  )
}

///|
pub fn FVec3::rotate_z(v : FVec3, angle_rad : Float) -> FVec3 {
  let cos_a = Float::from_double(@math.cos(angle_rad.to_double()))
  let sin_a = Float::from_double(@math.sin(angle_rad.to_double()))
  FVec3::new(
    v.x * cos_a - v.y * sin_a,
    v.x * sin_a + v.y * cos_a,
    v.z, //
  )
}

///|
pub fn FVec3::lerp(u : FVec3, v : FVec3, t : Float) -> FVec3 {
  let t = @cmp.maximum((0 : Float), @cmp.minimum((1 : Float), t))
  FVec3::new(
    u.x + (v.x - u.x) * t,
    u.y + (v.y - u.y) * t,
    u.z + (v.z - u.z) * t,
  )
}

///|
pub fn FVec3::almost_equal(u : FVec3, v : FVec3) -> Bool {
  (u.x - v.x).abs() <= EPSILON &&
  (u.y - v.y).abs() <= EPSILON &&
  (u.z - v.z).abs() <= EPSILON
}

///|
pub impl Eq for FVec3 with equal(u, v) {
  u.x == v.x && u.y == v.y && u.z == v.z
}
