///|
pub fn mat4_mul(a : Array[Float], b : Array[Float]) -> Array[Float] {
  if a.length() < 16 || b.length() < 16 {
    []
  } else {
    let out : Array[Float] = Array::make(16, 0.0F)
    let a00 = a[0]
    let a01 = a[1]
    let a02 = a[2]
    let a03 = a[3]
    let a10 = a[4]
    let a11 = a[5]
    let a12 = a[6]
    let a13 = a[7]
    let a20 = a[8]
    let a21 = a[9]
    let a22 = a[10]
    let a23 = a[11]
    let a30 = a[12]
    let a31 = a[13]
    let a32 = a[14]
    let a33 = a[15]
    let mut b0 = b[0]
    let mut b1 = b[1]
    let mut b2 = b[2]
    let mut b3 = b[3]
    out[0] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30
    out[1] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31
    out[2] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32
    out[3] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33
    b0 = b[4]
    b1 = b[5]
    b2 = b[6]
    b3 = b[7]
    out[4] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30
    out[5] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31
    out[6] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32
    out[7] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33
    b0 = b[8]
    b1 = b[9]
    b2 = b[10]
    b3 = b[11]
    out[8] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30
    out[9] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31
    out[10] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32
    out[11] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33
    b0 = b[12]
    b1 = b[13]
    b2 = b[14]
    b3 = b[15]
    out[12] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30
    out[13] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31
    out[14] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32
    out[15] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33
    out
  }
}

///|
pub fn mat4_ortho(
  left : Float,
  right : Float,
  bottom : Float,
  top : Float,
  near : Float,
  far : Float,
) -> Array[Float] {
  let lr = 1.0F / (left - right)
  let bt = 1.0F / (bottom - top)
  let nf = 1.0F / (near - far)
  [
    -2.0F * lr,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    -2.0F * bt,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    2.0F * nf,
    0.0F,
    (left + right) * lr,
    (top + bottom) * bt,
    (far + near) * nf,
    1.0F,
  ]
}

///|
pub fn mat4_perspective(
  fovy : Float,
  aspect : Float,
  near : Float,
  far : Float,
) -> Array[Float] {
  let f = 1.0F / @math.tanf(fovy / 2.0F)
  let nf = 1.0F / (near - far)
  [
    f / aspect,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    f,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    (far + near) * nf,
    -1.0F,
    0.0F,
    0.0F,
    2.0F * far * near * nf,
    0.0F,
  ]
}

///|
pub fn mat4_look_at(
  eye : Array[Float],
  center : Array[Float],
  up : Array[Float],
) -> Array[Float] {
  if eye.length() < 3 || center.length() < 3 || up.length() < 3 {
    []
  } else {
    let zx = eye[0] - center[0]
    let zy = eye[1] - center[1]
    let zz = eye[2] - center[2]
    let zlen = (zx * zx + zy * zy + zz * zz).sqrt()
    let nzx = if zlen == 0.0 { 0.0F } else { zx / zlen }
    let nzy = if zlen == 0.0 { 0.0F } else { zy / zlen }
    let nzz = if zlen == 0.0 { 0.0F } else { zz / zlen }
    let xx = up[1] * nzz - up[2] * nzy
    let xy = up[2] * nzx - up[0] * nzz
    let xz = up[0] * nzy - up[1] * nzx
    let xlen = (xx * xx + xy * xy + xz * xz).sqrt()
    let nxx = if xlen == 0.0 { 0.0F } else { xx / xlen }
    let nxy = if xlen == 0.0 { 0.0F } else { xy / xlen }
    let nxz = if xlen == 0.0 { 0.0F } else { xz / xlen }
    let yx = nzy * nxz - nzz * nxy
    let yy = nzz * nxx - nzx * nxz
    let yz = nzx * nxy - nzy * nxx
    [
      nxx,
      yx,
      nzx,
      0.0F,
      nxy,
      yy,
      nzy,
      0.0F,
      nxz,
      yz,
      nzz,
      0.0F,
      -(nxx * eye[0] + nxy * eye[1] + nxz * eye[2]),
      -(yx * eye[0] + yy * eye[1] + yz * eye[2]),
      -(nzx * eye[0] + nzy * eye[1] + nzz * eye[2]),
      1.0F,
    ]
  }
}
