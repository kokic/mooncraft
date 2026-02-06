const UP_VECTOR = [0, 1, 0];

function cameraFromYawPitch(out, px, py, pz, yaw, pitch) {
  const cosPitch = Math.cos(pitch);
  const dirX = Math.cos(yaw) * cosPitch;
  const dirY = Math.sin(pitch);
  const dirZ = Math.sin(yaw) * cosPitch;
  out.position[0] = px;
  out.position[1] = py;
  out.position[2] = pz;
  out.direction[0] = dirX;
  out.direction[1] = dirY;
  out.direction[2] = dirZ;
  out.center[0] = px + dirX;
  out.center[1] = py + dirY;
  out.center[2] = pz + dirZ;
  return out;
}

function mat4Perspective(out, fovy, aspect, near, far) {
  const f = 1 / Math.tan(fovy / 2);
  const nf = 1 / (near - far);
  out[0] = f / aspect;
  out[1] = 0;
  out[2] = 0;
  out[3] = 0;
  out[4] = 0;
  out[5] = f;
  out[6] = 0;
  out[7] = 0;
  out[8] = 0;
  out[9] = 0;
  out[10] = (far + near) * nf;
  out[11] = -1;
  out[12] = 0;
  out[13] = 0;
  out[14] = 2 * far * near * nf;
  out[15] = 0;
  return out;
}

function mat4Ortho(out, left, right, bottom, top, near, far) {
  const lr = 1 / (left - right);
  const bt = 1 / (bottom - top);
  const nf = 1 / (near - far);
  out[0] = -2 * lr;
  out[1] = 0;
  out[2] = 0;
  out[3] = 0;
  out[4] = 0;
  out[5] = -2 * bt;
  out[6] = 0;
  out[7] = 0;
  out[8] = 0;
  out[9] = 0;
  out[10] = 2 * nf;
  out[11] = 0;
  out[12] = (left + right) * lr;
  out[13] = (top + bottom) * bt;
  out[14] = (far + near) * nf;
  out[15] = 1;
  return out;
}

function mat4LookAt(out, eye, center, up) {
  const zx = eye[0] - center[0];
  const zy = eye[1] - center[1];
  const zz = eye[2] - center[2];
  const zLen = Math.hypot(zx, zy, zz);
  const nzx = zLen === 0 ? 0 : zx / zLen;
  const nzy = zLen === 0 ? 0 : zy / zLen;
  const nzz = zLen === 0 ? 0 : zz / zLen;
  const xx = up[1] * nzz - up[2] * nzy;
  const xy = up[2] * nzx - up[0] * nzz;
  const xz = up[0] * nzy - up[1] * nzx;
  const xLen = Math.hypot(xx, xy, xz);
  const nxx = xLen === 0 ? 0 : xx / xLen;
  const nxy = xLen === 0 ? 0 : xy / xLen;
  const nxz = xLen === 0 ? 0 : xz / xLen;
  const yx = nzy * nxz - nzz * nxy;
  const yy = nzz * nxx - nzx * nxz;
  const yz = nzx * nxy - nzy * nxx;
  out[0] = nxx;
  out[1] = yx;
  out[2] = nzx;
  out[3] = 0;
  out[4] = nxy;
  out[5] = yy;
  out[6] = nzy;
  out[7] = 0;
  out[8] = nxz;
  out[9] = yz;
  out[10] = nzz;
  out[11] = 0;
  out[12] = -(nxx * eye[0] + nxy * eye[1] + nxz * eye[2]);
  out[13] = -(yx * eye[0] + yy * eye[1] + yz * eye[2]);
  out[14] = -(nzx * eye[0] + nzy * eye[1] + nzz * eye[2]);
  out[15] = 1;
  return out;
}

function mat4Mul(out, a, b) {
  const a00 = a[0];
  const a01 = a[1];
  const a02 = a[2];
  const a03 = a[3];
  const a10 = a[4];
  const a11 = a[5];
  const a12 = a[6];
  const a13 = a[7];
  const a20 = a[8];
  const a21 = a[9];
  const a22 = a[10];
  const a23 = a[11];
  const a30 = a[12];
  const a31 = a[13];
  const a32 = a[14];
  const a33 = a[15];

  let b0 = b[0];
  let b1 = b[1];
  let b2 = b[2];
  let b3 = b[3];
  out[0] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30;
  out[1] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31;
  out[2] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32;
  out[3] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33;
  b0 = b[4];
  b1 = b[5];
  b2 = b[6];
  b3 = b[7];
  out[4] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30;
  out[5] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31;
  out[6] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32;
  out[7] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33;
  b0 = b[8];
  b1 = b[9];
  b2 = b[10];
  b3 = b[11];
  out[8] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30;
  out[9] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31;
  out[10] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32;
  out[11] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33;
  b0 = b[12];
  b1 = b[13];
  b2 = b[14];
  b3 = b[15];
  out[12] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30;
  out[13] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31;
  out[14] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32;
  out[15] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33;
  return out;
}

export {
  UP_VECTOR,
  cameraFromYawPitch,
  mat4Perspective,
  mat4Ortho,
  mat4LookAt,
  mat4Mul,
};
