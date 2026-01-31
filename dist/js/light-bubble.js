const DEFAULT_LIGHT_BUBBLE = {
  enabled: false,
  followCamera: true,
  position: [0, 0, 0],
  radius: 8.0,
  intensity: 1.2,
  ambient: 1.0,
};

const lightBubbleState = {
  enabled: DEFAULT_LIGHT_BUBBLE.enabled,
  followCamera: DEFAULT_LIGHT_BUBBLE.followCamera,
  position: [...DEFAULT_LIGHT_BUBBLE.position],
  radius: DEFAULT_LIGHT_BUBBLE.radius,
  intensity: DEFAULT_LIGHT_BUBBLE.intensity,
  ambient: DEFAULT_LIGHT_BUBBLE.ambient,
};

function clampNonNeg(value, fallback) {
  if (!Number.isFinite(value)) return fallback;
  return Math.max(0, value);
}

function syncLegacyGlobals() {
  if ("mcLightBubbleEnabled" in window) {
    lightBubbleState.enabled = window.mcLightBubbleEnabled !== false;
  }
  if ("mcLightBubbleRadius" in window) {
    lightBubbleState.radius = clampNonNeg(window.mcLightBubbleRadius, lightBubbleState.radius);
  }
  if ("mcLightBubbleIntensity" in window) {
    lightBubbleState.intensity = clampNonNeg(window.mcLightBubbleIntensity, lightBubbleState.intensity);
  }
  if ("mcLightBubbleAmbient" in window) {
    lightBubbleState.ambient = clampNonNeg(window.mcLightBubbleAmbient, lightBubbleState.ambient);
  }
}

const lightBubbleController = {
  enable() {
    lightBubbleState.enabled = true;
  },
  disable() {
    lightBubbleState.enabled = false;
  },
  setEnabled(enabled) {
    lightBubbleState.enabled = !!enabled;
  },
  setFollowCamera(follow) {
    lightBubbleState.followCamera = !!follow;
  },
  setPosition(x, y, z) {
    lightBubbleState.position[0] = Number.isFinite(x) ? x : lightBubbleState.position[0];
    lightBubbleState.position[1] = Number.isFinite(y) ? y : lightBubbleState.position[1];
    lightBubbleState.position[2] = Number.isFinite(z) ? z : lightBubbleState.position[2];
    lightBubbleState.followCamera = false;
  },
  setRadius(radius) {
    lightBubbleState.radius = clampNonNeg(radius, lightBubbleState.radius);
  },
  setIntensity(intensity) {
    lightBubbleState.intensity = clampNonNeg(intensity, lightBubbleState.intensity);
  },
  setAmbient(ambient) {
    lightBubbleState.ambient = clampNonNeg(ambient, lightBubbleState.ambient);
  },
  reset() {
    lightBubbleState.enabled = DEFAULT_LIGHT_BUBBLE.enabled;
    lightBubbleState.followCamera = DEFAULT_LIGHT_BUBBLE.followCamera;
    lightBubbleState.position[0] = DEFAULT_LIGHT_BUBBLE.position[0];
    lightBubbleState.position[1] = DEFAULT_LIGHT_BUBBLE.position[1];
    lightBubbleState.position[2] = DEFAULT_LIGHT_BUBBLE.position[2];
    lightBubbleState.radius = DEFAULT_LIGHT_BUBBLE.radius;
    lightBubbleState.intensity = DEFAULT_LIGHT_BUBBLE.intensity;
    lightBubbleState.ambient = DEFAULT_LIGHT_BUBBLE.ambient;
  },
  getState() {
    syncLegacyGlobals();
    return {
      enabled: lightBubbleState.enabled,
      followCamera: lightBubbleState.followCamera,
      position: [...lightBubbleState.position],
      radius: lightBubbleState.radius,
      intensity: lightBubbleState.intensity,
      ambient: lightBubbleState.ambient,
    };
  },
};

syncLegacyGlobals();
if (!window.mcLightBubble) {
  window.mcLightBubble = lightBubbleController;
}

export function getLightBubbleState() {
  syncLegacyGlobals();
  return lightBubbleState;
}

export function getLightBubbleController() {
  syncLegacyGlobals();
  return lightBubbleController;
}
