///|
pub struct Vec2[T] {
  x : T
  y : T
} derive(Show)

///|
pub fn[T] Vec2::new(x : T, y : T) -> Vec2[T] {
  Vec2::{ x, y }
}

///|
pub impl[T : Add] Add for Vec2[T] with add(u, v) {
  Vec2::new(u.x + v.x, u.y + v.y)
}

///|
pub impl[T : Sub] Sub for Vec2[T] with sub(u, v) {
  Vec2::new(u.x - v.x, u.y - v.y)
}

///|
pub impl[T : Neg] Neg for Vec2[T] with neg(u) {
  Vec2::new(-u.x, -u.y)
}

///|
pub fn[T : Mul] Vec2::scale(v : Vec2[T], s : T) -> Vec2[T] {
  Vec2::new(s * v.x, s * v.y)
}

///|
pub fn[T : Mul + Add] Vec2::dot(u : Vec2[T], v : Vec2[T]) -> T {
  u.x * v.x + u.y * v.y
}

///|
pub impl[T : Mul] Mul for Vec2[T] with mul(u : Vec2[T], v : Vec2[T]) -> Vec2[T] {
  Vec2::new(u.x * v.x, u.y * v.y)
}

///|
/// ```plain
/// |u.x u.y|
/// |v.x v.y|
/// ```
pub fn[T : Mul + Sub] Vec2::cross(u : Vec2[T], v : Vec2[T]) -> T {
  // u.x * v.y - u.y * v.x
  det2(u.x, u.y, v.x, v.y)
}

///|
pub type FVec2 = Vec2[Float]

///|
#alias(norm)
pub fn FVec2::eulidian_norm(v : FVec2) -> Float {
  (v.x * v.x + v.y * v.y).sqrt()
}

///|
pub fn FVec2::normalize(v : FVec2) -> FVec2? {
  let norm = FVec2::eulidian_norm(v)
  guard norm != 0.0 else { return None }
  Some(FVec2::scale(v, 1.0 / norm))
}

///|
pub fn FVec2::rotate(v : FVec2, angle_rad : Float) -> FVec2 {
  let cos_a = Float::from_double(@math.cos(angle_rad.to_double()))
  let sin_a = Float::from_double(@math.sin(angle_rad.to_double()))
  FVec2::new(v.x * cos_a - v.y * sin_a, v.x * sin_a + v.y * cos_a)
}

///|
pub fn FVec2::angle(u : FVec2, v : FVec2) -> Double {
  @math.atan2(v.y.to_double(), v.x.to_double()) -
  @math.atan2(u.y.to_double(), u.x.to_double())
}

///|
pub fn FVec2::lerp(u : FVec2, v : FVec2, t : Float) -> FVec2 {
  let t = @cmp.maximum((0 : Float), @cmp.minimum((1 : Float), t))
  FVec2::new(u.x + (v.x - u.x) * t, u.y + (v.y - u.y) * t)
}

///|
/// 1E-5
pub const EPSILON : Float = 0.00001F

///|
pub fn FVec2::almost_equal(u : FVec2, v : FVec2) -> Bool {
  (u.x - v.x).abs() <= EPSILON && (u.y - v.y).abs() <= EPSILON
}

///|
pub impl Eq for FVec2 with equal(u, v) {
  u.x == v.x && u.y == v.y
}
