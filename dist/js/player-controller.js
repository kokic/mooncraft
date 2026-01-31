import { logOnce } from "./logging.js";

// Player controller: input handling, movement, and camera direction.

function cameraFromYawPitch(position, yaw, pitch) {
  const cosPitch = Math.cos(pitch);
  const dir = [
    Math.cos(yaw) * cosPitch,
    Math.sin(pitch),
    Math.sin(yaw) * cosPitch,
  ];
  return {
    position,
    direction: dir,
    center: [
      position[0] + dir[0],
      position[1] + dir[1],
      position[2] + dir[2],
    ],
  };
}

function createPlayerController({
  canvas,
  worldMinY,
  spawnPosition,
  speed = 8,
  sensitivity = 0.0014,
  gameMode,
  getBlockAt = null,
  isSolidBlock = null,
  getBlockAabb = null,
  entityHeight = 1.8,
  entityRadius = 0.3,
}) {
  const state = {
    position: [...spawnPosition],
    yaw: -Math.PI * 0.75,
    pitch: -0.35,
    speed,
    gameMode,
    entityHeight,
    entityRadius,
    keys: new Set(),
    lastTime: performance.now(),
    centerKey: "0,0,0",
    isRun: false,
    lastWDownTime: 0,
    lastWUpTime: 0,
    wDown: false,
  };

  const onKey = (event, isDown) => {
    if (document.pointerLockElement !== canvas) return;
    const key = event.code;
    if (isDown) {
      state.keys.add(key);
      if (key === "KeyW") {
        if (!state.wDown) {
          const now = performance.now();
          if (now - state.lastWUpTime < 300) {
            state.isRun = true;
          }
          state.lastWDownTime = now;
          state.wDown = true;
        }
      }
    } else {
      state.keys.delete(key);
      if (key === "KeyW") {
        state.isRun = false;
        state.wDown = false;
        state.lastWUpTime = performance.now();
      }
    }
  };

  const onMouseMove = (event) => {
    if (document.pointerLockElement !== canvas) return;
    // 0.0012 (a bit slow) - 0.016 (a bit fast)
    state.yaw += event.movementX * sensitivity;
    state.pitch -= event.movementY * sensitivity;
    state.pitch = Math.max(-1.55, Math.min(1.55, state.pitch));
  };

  const onClick = () => {
    canvas.requestPointerLock();
  };

  const onKeyDown = (event) => onKey(event, true);
  const onKeyUp = (event) => onKey(event, false);
  window.addEventListener("keydown", onKeyDown);
  window.addEventListener("keyup", onKeyUp);
  document.addEventListener("mousemove", onMouseMove);
  canvas.addEventListener("click", onClick);

  const isSolidAt = (x, y, z) => {
    if (typeof getBlockAt !== "function") {
      logOnce("error", "player:getBlockAt-missing", "[player] getBlockAt is not a function");
      return false;
    }
    const id = getBlockAt(x, y, z);
    if (id == null) return false;
    if (typeof isSolidBlock === "function") {
      return isSolidBlock(id);
    }
    return id !== 0;
  };

  const getBlockAabbAt = (x, y, z) => {
    if (typeof getBlockAt !== "function") {
      logOnce("error", "player:getBlockAt-missing-aabb", "[player] getBlockAt is not a function");
      return null;
    }
    const id = getBlockAt(x, y, z);
    if (id == null) return null;
    if (typeof getBlockAabb === "function") return getBlockAabb(id);
    if (typeof isSolidBlock === "function" && !isSolidBlock(id)) {
      return null;
    }
    return id !== 0 ? { min: [0, 0, 0], max: [1, 1, 1] } : null;
  };

  const intersects = (
    aMinX, aMinY, aMinZ,
    aMaxX, aMaxY, aMaxZ,
    bMinX, bMinY, bMinZ,
    bMaxX, bMaxY, bMaxZ,
  ) => (
    aMaxX > bMinX &&
    aMinX < bMaxX &&
    aMaxY > bMinY &&
    aMinY < bMaxY &&
    aMaxZ > bMinZ &&
    aMinZ < bMaxZ
  );

  const moveAxis = (pos, axis, delta) => {
    if (delta === 0) return pos[axis];
    const radius = state.entityRadius;
    const height = state.entityHeight;
    const dir = Math.sign(delta);
    let next = pos[axis] + delta;
    const eps = 1e-4;
    if (axis === 0) {
      const targetX = next + dir * radius;
      const blockX = Math.floor(targetX);
      const minY = Math.floor(pos[1]);
      const maxY = Math.floor(pos[1] + height);
      const minZ = Math.floor(pos[2] - radius);
      const maxZ = Math.floor(pos[2] + radius);
      const entMinX = next - radius;
      const entMaxX = next + radius;
      const entMinY = pos[1];
      const entMaxY = pos[1] + height;
      const entMinZ = pos[2] - radius;
      const entMaxZ = pos[2] + radius;
      for (let by = minY; by <= maxY; by += 1) {
        for (let bz = minZ; bz <= maxZ; bz += 1) {
          const aabb = getBlockAabbAt(blockX, by, bz);
          if (!aabb) continue;
          const bMinX = blockX + aabb.min[0];
          const bMaxX = blockX + aabb.max[0];
          const bMinY = by + aabb.min[1];
          const bMaxY = by + aabb.max[1];
          const bMinZ = bz + aabb.min[2];
          const bMaxZ = bz + aabb.max[2];
          if (!intersects(
            entMinX, entMinY, entMinZ,
            entMaxX, entMaxY, entMaxZ,
            bMinX, bMinY, bMinZ,
            bMaxX, bMaxY, bMaxZ,
          )) continue;
          if (dir > 0) {
            next = bMinX - radius - eps;
          } else {
            next = bMaxX + radius + eps;
          }
          return next;
        }
      }
      return next;
    }
    if (axis === 2) {
      const targetZ = next + dir * radius;
      const blockZ = Math.floor(targetZ);
      const minY = Math.floor(pos[1]);
      const maxY = Math.floor(pos[1] + height);
      const minX = Math.floor(pos[0] - radius);
      const maxX = Math.floor(pos[0] + radius);
      const entMinX = pos[0] - radius;
      const entMaxX = pos[0] + radius;
      const entMinY = pos[1];
      const entMaxY = pos[1] + height;
      const entMinZ = next - radius;
      const entMaxZ = next + radius;
      for (let by = minY; by <= maxY; by += 1) {
        for (let bx = minX; bx <= maxX; bx += 1) {
          const aabb = getBlockAabbAt(bx, by, blockZ);
          if (!aabb) continue;
          const bMinX = bx + aabb.min[0];
          const bMaxX = bx + aabb.max[0];
          const bMinY = by + aabb.min[1];
          const bMaxY = by + aabb.max[1];
          const bMinZ = blockZ + aabb.min[2];
          const bMaxZ = blockZ + aabb.max[2];
          if (!intersects(
            entMinX, entMinY, entMinZ,
            entMaxX, entMaxY, entMaxZ,
            bMinX, bMinY, bMinZ,
            bMaxX, bMaxY, bMaxZ,
          )) continue;
          if (dir > 0) {
            next = bMinZ - radius - eps;
          } else {
            next = bMaxZ + radius + eps;
          }
          return next;
        }
      }
      return next;
    }
    if (axis === 1) {
      const targetY = dir > 0 ? next + height : next;
      const blockY = Math.floor(targetY);
      const minX = Math.floor(pos[0] - radius);
      const maxX = Math.floor(pos[0] + radius);
      const minZ = Math.floor(pos[2] - radius);
      const maxZ = Math.floor(pos[2] + radius);
      const entMinX = pos[0] - radius;
      const entMaxX = pos[0] + radius;
      const entMinY = next;
      const entMaxY = next + height;
      const entMinZ = pos[2] - radius;
      const entMaxZ = pos[2] + radius;
      for (let bx = minX; bx <= maxX; bx += 1) {
        for (let bz = minZ; bz <= maxZ; bz += 1) {
          const aabb = getBlockAabbAt(bx, blockY, bz);
          if (!aabb) continue;
          const bMinX = bx + aabb.min[0];
          const bMaxX = bx + aabb.max[0];
          const bMinY = blockY + aabb.min[1];
          const bMaxY = blockY + aabb.max[1];
          const bMinZ = bz + aabb.min[2];
          const bMaxZ = bz + aabb.max[2];
          if (!intersects(
            entMinX, entMinY, entMinZ,
            entMaxX, entMaxY, entMaxZ,
            bMinX, bMinY, bMinZ,
            bMaxX, bMaxY, bMaxZ,
          )) continue;
          if (dir > 0) {
            next = bMinY - height - eps;
          } else {
            next = bMaxY + eps;
          }
          return next;
        }
      }
      return next;
    }
    return next;
  };

  const update = (delta) => {
    const forward = [Math.cos(state.yaw), 0, Math.sin(state.yaw)];
    const right = [-forward[2], 0, forward[0]];

    let velocity = state.speed * delta;
    if (state.keys.has("ControlLeft") || state.keys.has("ControlRight")) {
      velocity *= 2.0;
    }
    if (state.isRun && state.keys.has("KeyW")) {
      velocity *= 2.0;
    }

    let dx = 0;
    let dy = 0;
    let dz = 0;
    if (state.keys.has("KeyW")) {
      dx += forward[0] * velocity;
      dz += forward[2] * velocity;
    }
    if (state.keys.has("KeyS")) {
      dx -= forward[0] * velocity;
      dz -= forward[2] * velocity;
    }
    if (state.keys.has("KeyA")) {
      dx -= right[0] * velocity;
      dz -= right[2] * velocity;
    }
    if (state.keys.has("KeyD")) {
      dx += right[0] * velocity;
      dz += right[2] * velocity;
    }
    if (state.keys.has("Space")) {
      dy += velocity;
    }
    if (state.keys.has("ShiftLeft") || state.keys.has("ShiftRight")) {
      dy -= velocity;
    }

    if (state.gameMode === "spectator" || typeof getBlockAt !== "function") {
      state.position[0] += dx;
      state.position[1] += dy;
      state.position[2] += dz;
    } else {
      state.position[0] = moveAxis(state.position, 0, dx);
      state.position[2] = moveAxis(state.position, 2, dz);
      state.position[1] = moveAxis(state.position, 1, dy);
    }

    const minY = worldMinY - 1;
    state.position[1] = Math.max(minY, state.position[1]);
  };

  const dispose = () => {
    window.removeEventListener("keydown", onKeyDown);
    window.removeEventListener("keyup", onKeyUp);
    document.removeEventListener("mousemove", onMouseMove);
    canvas.removeEventListener("click", onClick);
  };

  const setGameMode = (mode) => {
    if (mode !== "creative" && mode !== "spectator") return;
    state.gameMode = mode;
  };

  return { state, update, dispose, setGameMode };
}

export {
  cameraFromYawPitch,
  createPlayerController,
};
