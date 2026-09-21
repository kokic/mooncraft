///|
pub fn quat_normalize(
  out : Array[Double],
  quat : Array[Double],
) -> Array[Double] {
  let length = (quat[0] * quat[0] +
  quat[1] * quat[1] +
  quat[2] * quat[2] +
  quat[3] * quat[3]).sqrt()
  if length <= 0.0 {
    out[0] = 0.0
    out[1] = 0.0
    out[2] = 0.0
    out[3] = 1.0
  } else {
    let inv = 1.0 / length
    out[0] = quat[0] * inv
    out[1] = quat[1] * inv
    out[2] = quat[2] * inv
    out[3] = quat[3] * inv
  }
  out
}

///|
pub fn quat_mul(
  out : Array[Double],
  left : Array[Double],
  right : Array[Double],
) -> Array[Double] {
  let ax = left[0]
  let ay = left[1]
  let az = left[2]
  let aw = left[3]
  let bx = right[0]
  let by = right[1]
  let bz = right[2]
  let bw = right[3]
  out[0] = aw * bx + ax * bw + ay * bz - az * by
  out[1] = aw * by - ax * bz + ay * bw + az * bx
  out[2] = aw * bz + ax * by - ay * bx + az * bw
  out[3] = aw * bw - ax * bx - ay * by - az * bz
  out
}

///|
pub fn quat_apply_yaw_offset(
  out : Array[Double],
  quat : Array[Double],
  yaw : Double,
) -> Array[Double] {
  let half_yaw = yaw * 0.5
  let sy = @math.sin(half_yaw)
  let cy = @math.cos(half_yaw)
  let qx = quat[0]
  let qy = quat[1]
  let qz = quat[2]
  let qw = quat[3]
  out[0] = cy * qx + sy * qz
  out[1] = cy * qy + sy * qw
  out[2] = cy * qz - sy * qx
  out[3] = cy * qw - sy * qy
  quat_normalize(out, out)
}

///|
pub fn quat_from_yaw_pitch(
  out : Array[Double],
  yaw : Double,
  pitch : Double,
) -> Array[Double] {
  let half_yaw = yaw * 0.5
  let half_pitch = pitch * 0.5
  let sy = @math.sin(half_yaw)
  let cy = @math.cos(half_yaw)
  let sx = @math.sin(half_pitch)
  let cx = @math.cos(half_pitch)
  out[0] = cy * sx
  out[1] = sy * cx
  out[2] = -sy * sx
  out[3] = cy * cx
  quat_normalize(out, out)
}

///|
pub fn quat_slerp(
  out : Array[Double],
  left : Array[Double],
  right : Array[Double],
  t : Double,
) -> Array[Double] {
  let ax = left[0]
  let ay = left[1]
  let az = left[2]
  let aw = left[3]
  let mut bx = right[0]
  let mut by = right[1]
  let mut bz = right[2]
  let mut bw = right[3]
  let mut cos = ax * bx + ay * by + az * bz + aw * bw
  if cos < 0.0 {
    cos = -cos
    bx = -bx
    by = -by
    bz = -bz
    bw = -bw
  }
  if cos > 0.9995 {
    out[0] = ax + (bx - ax) * t
    out[1] = ay + (by - ay) * t
    out[2] = az + (bz - az) * t
    out[3] = aw + (bw - aw) * t
    return quat_normalize(out, out)
  }
  let clamped_cos = if cos < -1.0 {
    -1.0
  } else if cos > 1.0 {
    1.0
  } else {
    cos
  }
  let theta = @math.acos(clamped_cos)
  let sin_theta = @math.sin(theta)
  let w0 = @math.sin((1.0 - t) * theta) / sin_theta
  let w1 = @math.sin(t * theta) / sin_theta
  out[0] = ax * w0 + bx * w1
  out[1] = ay * w0 + by * w1
  out[2] = az * w0 + bz * w1
  out[3] = aw * w0 + bw * w1
  out
}
