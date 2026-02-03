// Player controller: input handling and movement.

function createPlayerController({
  canvas,
  worldMinY,
  spawnPosition,
  speed = 8,
  sensitivity = 0.0014,
  gameMode,
  chunkMap = null,
  chunkSize = 0,
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

  const buildMoveInput = () => ({
    forward: state.keys.has("KeyW"),
    back: state.keys.has("KeyS"),
    left: state.keys.has("KeyA"),
    right: state.keys.has("KeyD"),
    up: state.keys.has("Space"),
    down: state.keys.has("ShiftLeft") || state.keys.has("ShiftRight"),
    sprint: state.isRun && state.keys.has("KeyW"),
    fast: state.keys.has("ControlLeft") || state.keys.has("ControlRight"),
  });

  const applyFallbackMove = (input, delta) => {
    const forward = [Math.cos(state.yaw), 0, Math.sin(state.yaw)];
    const right = [-forward[2], 0, forward[0]];
    let velocity = state.speed * delta;
    if (input.fast) velocity *= 2.0;
    if (input.sprint && input.forward) velocity *= 2.0;
    let dx = 0;
    let dy = 0;
    let dz = 0;
    if (input.forward) {
      dx += forward[0] * velocity;
      dz += forward[2] * velocity;
    }
    if (input.back) {
      dx -= forward[0] * velocity;
      dz -= forward[2] * velocity;
    }
    if (input.left) {
      dx -= right[0] * velocity;
      dz -= right[2] * velocity;
    }
    if (input.right) {
      dx += right[0] * velocity;
      dz += right[2] * velocity;
    }
    if (input.up) dy += velocity;
    if (input.down) dy -= velocity;
    state.position[0] += dx;
    state.position[1] += dy;
    state.position[2] += dz;
  };

  const update = (delta) => {
    const input = buildMoveInput();
    const mover = window.mcMovePlayer;
    if (typeof mover === "function" && chunkMap && chunkSize) {
      const next = mover(
        chunkMap,
        chunkSize,
        state.position,
        state.yaw,
        input,
        state.speed,
        delta,
        state.entityHeight,
        state.entityRadius,
        worldMinY,
        state.gameMode,
      );
      if (Array.isArray(next) && next.length >= 3) {
        state.position[0] = next[0];
        state.position[1] = next[1];
        state.position[2] = next[2];
      } else {
        applyFallbackMove(input, delta);
      }
    } else {
      applyFallbackMove(input, delta);
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
  createPlayerController,
};
