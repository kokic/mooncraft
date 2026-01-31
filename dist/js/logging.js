function createLogOnce() {
  const seen = new Set();
  return (level, key, ...args) => {
    if (seen.has(key)) return;
    seen.add(key);
    console[level](...args);
  };
}

const logOnce = createLogOnce();

export {
  logOnce,
  createLogOnce,
};
