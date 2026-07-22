///|
fn sample_keyframe(times : Float32Array, t : Float) -> Int {
  let count = times.length()
  if count <= 1 { return 0 }
  let times_vals = times.values()
  if t <= Float::from_double(times_vals[0]) { return 0 }
  let last = count - 1
  if t >= Float::from_double(times_vals[last]) { return last - 1 }
  let mut lo = 0
  let mut hi = last
  while lo + 1 < hi {
    let mid = (lo + hi) >> 1
    if Float::from_double(times_vals[mid]) <= t { lo = mid } else { hi = mid }
  }
  lo
}

///|
fn slerp_result(a : Array[Double], b : Array[Double], frac : Float) -> Array[Double] {
  let out = [0.0, 0.0, 0.0, 1.0]
  ignore(@math3d.quat_slerp(out, a, b, frac.to_double()))
  out
}

///|
pub fn sample_animation_channel(
  input : Float32Array,
  output : Float32Array,
  path : String,
  interpolation : String,
  time : Float,
) -> Float32Array {
  let comps = if path == "rotation" { 4 } else { 3 }
  let k = sample_keyframe(input, time)
  let input_vals = input.values()
  let t0 = Float::from_double(input_vals[k])
  let next = if k + 1 < input.length() { k + 1 } else { k }
  let t1 = Float::from_double(input_vals[next])
  let f = if t1 > t0 { (time - t0) / (t1 - t0) } else { 0.0F }
  let frac = if interpolation == "STEP" { 0.0F } else { f }
  let out = Float32Array::new(comps)
  let out_vals = out.values()
  let output_vals = output.values()
  if path == "rotation" {
    let i0 = k * 4
    let i1 = next * 4
    let qa = [output_vals[i0], output_vals[i0 + 1], output_vals[i0 + 2], output_vals[i0 + 3]]
    let qb = [output_vals[i1], output_vals[i1 + 1], output_vals[i1 + 2], output_vals[i1 + 3]]
    let result = slerp_result(qa, qb, frac)
    for i in 0..<4 { out_vals[i] = result[i] }
  } else {
    let mul = 3
    let i0 = k * mul
    let i1 = next * mul
    for c in 0..<comps {
      let v0 = Float::from_double(output_vals[i0 + c])
      let v1 = Float::from_double(output_vals[i1 + c])
      out_vals[c] = (v0 + (v1 - v0) * frac).to_double()
    }
  }
  out
}

///|
pub fn compute_node_world(
  parent_world : Float32Array?,
  local_t : Array[Double],
  local_r : Array[Double],
  local_s : Array[Double],
) -> Float32Array {
  let local_mat = mat4_create()
  ignore(mat4_from_trs(local_mat, local_t, local_r, local_s))
  match parent_world {
    Some(parent) => {
      let out = mat4_create()
      ignore(mat4_mul(out, parent, local_mat))
      out
    }
    None => local_mat
  }
}
