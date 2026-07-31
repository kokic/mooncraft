///|
pub fn mat4_create() -> @ffi.Float32Array {
  let matrix = @ffi.Float32Array::new(16)
  let out = matrix.values()
  out[0] = 1.0
  out[5] = 1.0
  out[10] = 1.0
  out[15] = 1.0
  matrix
}

///|
pub fn mat4_copy(
  out : @ffi.Float32Array,
  source : @ffi.Float32Array,
) -> @ffi.Float32Array {
  out.copy_from(source)
  out
}

///|
pub fn mat4_perspective(
  matrix : @ffi.Float32Array,
  fovy : Double,
  aspect : Double,
  near : Double,
  far : Double,
) -> @ffi.Float32Array {
  let out = matrix.values()
  let f = 1.0 / @math.tan(fovy / 2.0)
  let nf = 1.0 / (near - far)
  out[0] = f / aspect
  out[1] = 0.0
  out[2] = 0.0
  out[3] = 0.0
  out[4] = 0.0
  out[5] = f
  out[6] = 0.0
  out[7] = 0.0
  out[8] = 0.0
  out[9] = 0.0
  out[10] = (far + near) * nf
  out[11] = -1.0
  out[12] = 0.0
  out[13] = 0.0
  out[14] = 2.0 * far * near * nf
  out[15] = 0.0
  matrix
}

///|
pub fn mat4_ortho(
  matrix : @ffi.Float32Array,
  left : Double,
  right : Double,
  bottom : Double,
  top : Double,
  near : Double,
  far : Double,
) -> @ffi.Float32Array {
  let out = matrix.values()
  let lr = 1.0 / (left - right)
  let bt = 1.0 / (bottom - top)
  let nf = 1.0 / (near - far)
  out[0] = -2.0 * lr
  out[1] = 0.0
  out[2] = 0.0
  out[3] = 0.0
  out[4] = 0.0
  out[5] = -2.0 * bt
  out[6] = 0.0
  out[7] = 0.0
  out[8] = 0.0
  out[9] = 0.0
  out[10] = 2.0 * nf
  out[11] = 0.0
  out[12] = (left + right) * lr
  out[13] = (top + bottom) * bt
  out[14] = (far + near) * nf
  out[15] = 1.0
  matrix
}

///|
pub fn mat4_look_at(
  matrix : @ffi.Float32Array,
  eye : Array[Double],
  center : Array[Double],
  up : Array[Double],
) -> @ffi.Float32Array {
  let out = matrix.values()
  let zx = eye[0] - center[0]
  let zy = eye[1] - center[1]
  let zz = eye[2] - center[2]
  let z_len = (zx * zx + zy * zy + zz * zz).sqrt()
  let nzx = if z_len == 0.0 { 0.0 } else { zx / z_len }
  let nzy = if z_len == 0.0 { 0.0 } else { zy / z_len }
  let nzz = if z_len == 0.0 { 0.0 } else { zz / z_len }
  let xx = up[1] * nzz - up[2] * nzy
  let xy = up[2] * nzx - up[0] * nzz
  let xz = up[0] * nzy - up[1] * nzx
  let x_len = (xx * xx + xy * xy + xz * xz).sqrt()
  let nxx = if x_len == 0.0 { 0.0 } else { xx / x_len }
  let nxy = if x_len == 0.0 { 0.0 } else { xy / x_len }
  let nxz = if x_len == 0.0 { 0.0 } else { xz / x_len }
  let yx = nzy * nxz - nzz * nxy
  let yy = nzz * nxx - nzx * nxz
  let yz = nzx * nxy - nzy * nxx
  out[0] = nxx
  out[1] = yx
  out[2] = nzx
  out[3] = 0.0
  out[4] = nxy
  out[5] = yy
  out[6] = nzy
  out[7] = 0.0
  out[8] = nxz
  out[9] = yz
  out[10] = nzz
  out[11] = 0.0
  out[12] = -(nxx * eye[0] + nxy * eye[1] + nxz * eye[2])
  out[13] = -(yx * eye[0] + yy * eye[1] + yz * eye[2])
  out[14] = -(nzx * eye[0] + nzy * eye[1] + nzz * eye[2])
  out[15] = 1.0
  matrix
}

///|
pub fn mat4_mul(
  matrix : @ffi.Float32Array,
  left : @ffi.Float32Array,
  right : @ffi.Float32Array,
) -> @ffi.Float32Array {
  let out = matrix.values()
  let a = left.values()
  let b = right.values()
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
  matrix
}

///|
pub fn mat4_from_trs(
  matrix : @ffi.Float32Array,
  translation : Array[Double],
  rotation : Array[Double],
  scale : Array[Double],
) -> @ffi.Float32Array {
  let out = matrix.values()
  let x = rotation[0]
  let y = rotation[1]
  let z = rotation[2]
  let w = rotation[3]
  let x2 = x + x
  let y2 = y + y
  let z2 = z + z
  let xx = x * x2
  let xy = x * y2
  let xz = x * z2
  let yy = y * y2
  let yz = y * z2
  let zz = z * z2
  let wx = w * x2
  let wy = w * y2
  let wz = w * z2
  let sx = scale[0]
  let sy = scale[1]
  let sz = scale[2]
  out[0] = (1.0 - (yy + zz)) * sx
  out[1] = (xy + wz) * sx
  out[2] = (xz - wy) * sx
  out[3] = 0.0
  out[4] = (xy - wz) * sy
  out[5] = (1.0 - (xx + zz)) * sy
  out[6] = (yz + wx) * sy
  out[7] = 0.0
  out[8] = (xz + wy) * sz
  out[9] = (yz - wx) * sz
  out[10] = (1.0 - (xx + yy)) * sz
  out[11] = 0.0
  out[12] = translation[0]
  out[13] = translation[1]
  out[14] = translation[2]
  out[15] = 1.0
  matrix
}

///|
pub fn transform_point(
  out : Array[Double],
  matrix : @ffi.Float32Array,
  point : Array[Double],
) -> Array[Double] {
  let m = matrix.values()
  let x = point[0]
  let y = point[1]
  let z = point[2]
  out[0] = m[0] * x + m[4] * y + m[8] * z + m[12]
  out[1] = m[1] * x + m[5] * y + m[9] * z + m[13]
  out[2] = m[2] * x + m[6] * y + m[10] * z + m[14]
  out
}
