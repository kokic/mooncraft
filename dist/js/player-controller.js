// Browser input adapter for the MoonBit-owned player runtime.

function createPlayerController({
  canvas,
  sensitivity = 0.0014,
}) {
  const readSnapshot = window.mcPlayerSnapshot;
  const setMoveIntent = window.mcSetPlayerMoveIntent;
  const addLookIntent = window.mcAddPlayerLookIntent;
  const tickPlayer = window.mcTickPlayer;
  if (typeof readSnapshot !== "function" ||
    typeof setMoveIntent !== "function" ||
    typeof addLookIntent !== "function" ||
    typeof tickPlayer !== "function") {
    throw new Error("MoonBit player runtime is unavailable");
  }

  const state = {
    position: [0, 0, 0],
    yaw: 0,
    pitch: 0,
    entityHeight: 1.8,
    entityRadius: 0.3,
  };
  const keys = new Set();
  let isRun = false;
  let lastWUpTime = 0;
  let wDown = false;

  const syncSnapshot = (snapshot) => {
    const position = Array.from(snapshot?.position ?? []).map(Number);
    if (position.length < 3 || !position.slice(0, 3).every(Number.isFinite)) {
      throw new Error("MoonBit player snapshot has an invalid position");
    }
    const yaw = Number(snapshot?.yaw);
    const pitch = Number(snapshot?.pitch);
    if (!Number.isFinite(yaw) || !Number.isFinite(pitch)) {
      throw new Error("MoonBit player snapshot has an invalid orientation");
    }
    state.position[0] = position[0];
    state.position[1] = position[1];
    state.position[2] = position[2];
    state.yaw = yaw;
    state.pitch = pitch;
    state.entityHeight = Number(snapshot?.entity_height ?? 1.8);
    state.entityRadius = Number(snapshot?.entity_radius ?? 0.3);
    return state;
  };

  syncSnapshot(readSnapshot());

  const onKey = (event, isDown) => {
    if (document.pointerLockElement !== canvas) return;
    const key = event.code;
    if (isDown) {
      keys.add(key);
      if (key === "KeyW" && !wDown) {
        const now = performance.now();
        if (now - lastWUpTime < 300) isRun = true;
        wDown = true;
      }
      return;
    }
    keys.delete(key);
    if (key === "KeyW") {
      isRun = false;
      wDown = false;
      lastWUpTime = performance.now();
    }
  };

  const onMouseMove = (event) => {
    if (document.pointerLockElement !== canvas) return;
    addLookIntent(
      event.movementX * sensitivity,
      -event.movementY * sensitivity,
    );
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

  const buildMoveIntent = (active) => ({
    forward: active && keys.has("KeyW"),
    back: active && keys.has("KeyS"),
    left: active && keys.has("KeyA"),
    right: active && keys.has("KeyD"),
    up: active && keys.has("Space"),
    down: active && (keys.has("ShiftLeft") || keys.has("ShiftRight")),
    sprint: active && isRun && keys.has("KeyW"),
    fast: active && (keys.has("ControlLeft") || keys.has("ControlRight")),
  });

  const update = (delta, active = true) => {
    setMoveIntent(buildMoveIntent(active));
    syncSnapshot(tickPlayer(delta));
  };

  const dispose = () => {
    window.removeEventListener("keydown", onKeyDown);
    window.removeEventListener("keyup", onKeyUp);
    document.removeEventListener("mousemove", onMouseMove);
    canvas.removeEventListener("click", onClick);
  };

  return { state, update, dispose };
}

export {
  createPlayerController,
};
