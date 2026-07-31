///|
fn box_face_corners(
  face : @shape.FaceName,
  min : (Float, Float, Float),
  max : (Float, Float, Float),
) -> (
  (Float, Float, Float),
  (Float, Float, Float),
  (Float, Float, Float),
  (Float, Float, Float),
) {
  let (x0, y0, z0) = min
  let (x1, y1, z1) = max
  match face {
    @shape.FaceName::PosX =>
      ((x1, y0, z0), (x1, y0, z1), (x1, y1, z1), (x1, y1, z0))
    @shape.FaceName::NegX =>
      ((x0, y0, z1), (x0, y0, z0), (x0, y1, z0), (x0, y1, z1))
    @shape.FaceName::PosY =>
      ((x0, y1, z1), (x0, y1, z0), (x1, y1, z0), (x1, y1, z1))
    @shape.FaceName::NegY =>
      ((x0, y0, z0), (x0, y0, z1), (x1, y0, z1), (x1, y0, z0))
    @shape.FaceName::PosZ =>
      ((x1, y0, z1), (x0, y0, z1), (x0, y1, z1), (x1, y1, z1))
    @shape.FaceName::NegZ =>
      ((x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0))
  }
}

///|
fn face_corners_world(
  face : @shape.FaceGeom,
  x : Int,
  y : Int,
  z : Int,
  custom_box : ((Float, Float, Float), (Float, Float, Float))?,
) -> (
  (Float, Float, Float),
  (Float, Float, Float),
  (Float, Float, Float),
  (Float, Float, Float),
) {
  match custom_box {
    Some((min, max)) => {
      let (a, b, c, d) = box_face_corners(face.name, min, max)
      let (ax, ay, az) = a
      let (bx, by, bz) = b
      let (cx, cy, cz) = c
      let (dx, dy, dz) = d
      let ox = Float::from_int(x)
      let oy = Float::from_int(y)
      let oz = Float::from_int(z)
      (
        (ax + ox, ay + oy, az + oz),
        (bx + ox, by + oy, bz + oz),
        (cx + ox, cy + oy, cz + oz),
        (dx + ox, dy + oy, dz + oz),
      )
    }
    None => {
      let a = face.corners[0]
      let b = face.corners[1]
      let c = face.corners[2]
      let d = face.corners[3]
      let (ax, ay, az) = a
      let (bx, by, bz) = b
      let (cx, cy, cz) = c
      let (dx, dy, dz) = d
      (
        (
          Float::from_int(ax + x),
          Float::from_int(ay + y),
          Float::from_int(az + z),
        ),
        (
          Float::from_int(bx + x),
          Float::from_int(by + y),
          Float::from_int(bz + z),
        ),
        (
          Float::from_int(cx + x),
          Float::from_int(cy + y),
          Float::from_int(cz + z),
        ),
        (
          Float::from_int(dx + x),
          Float::from_int(dy + y),
          Float::from_int(dz + z),
        ),
      )
    }
  }
}

///|
fn is_chunk_boundary_face(
  x : Int,
  y : Int,
  z : Int,
  nx : Int,
  ny : Int,
  nz : Int,
  size : Int,
) -> Bool {
  (nx == -1 && x == 0) ||
  (nx == 1 && x == size - 1) ||
  (ny == -1 && y == 0) ||
  (ny == 1 && y == size - 1) ||
  (nz == -1 && z == 0) ||
  (nz == 1 && z == size - 1)
}
