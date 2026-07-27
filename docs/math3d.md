# Math3D

## Camera

`camera_from_yaw_pitch_into` computes a tuple of (position, direction, center) from a position, yaw, and pitch:
- Forward direction: `(-sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch))`
- Directly fills the target tuple to avoid allocations per frame

The up vector is hardcoded to `(0, 1, 0)`.

**WIP**: Camera roll is not supported. The up vector is always world-up.

## Quaternion

All operations work on `Array[Double]` (4 elements) for direct FFI compatibility with WebGL:

- `quat_normalize` — in-place normalization
- `quat_mul` — Hamilton product
- `quat_apply_yaw_offset` — multiply by a pure yaw-axis quaternion (rotation around Y)
- `quat_from_yaw_pitch` — construct quaternion from Euler yaw and pitch
- `quat_slerp` — spherical linear interpolation for smooth rotation transitions

## Matrix

Pure MoonBit implementations of 4×4 matrix operations, all operating on `Float32Array` wrappers for zero-copy WebGL interop:

- `mat4_create` — identity matrix
- `mat4_perspective` — perspective projection from FOV, aspect, near/far
- `mat4_ortho` — orthographic projection
- `mat4_look_at` — view matrix from eye, center, up
- `mat4_mul` — 4×4 matrix multiplication
- `mat4_from_trs` — compose model matrix from translation, rotation (quaternion), scale
- `transform_point` — multiply a 3D point by a 4×4 matrix

**WIP**: Matrix operations are implemented but the camera system currently bypasses them — the JS renderer computes projection/view matrices directly from yaw/pitch and FOV. The MoonBit matrix functions are available but not the primary rendering path.
