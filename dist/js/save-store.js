const DATABASE_NAME = "mooncraft";
const DATABASE_VERSION = 3;
const SAVE_STORE_NAME = "saves";

let databasePromise = null;

function requestResult(request) {
  return new Promise((resolve, reject) => {
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error ?? new Error("IndexedDB request failed"));
  });
}

function transactionResult(transaction) {
  return new Promise((resolve, reject) => {
    transaction.oncomplete = () => resolve();
    transaction.onerror = () => reject(transaction.error ?? new Error("IndexedDB transaction failed"));
    transaction.onabort = () => reject(transaction.error ?? new Error("IndexedDB transaction aborted"));
  });
}

function openDatabase() {
  if (databasePromise) return databasePromise;
  if (typeof globalThis.indexedDB === "undefined") {
    return Promise.reject(new Error("IndexedDB is unavailable"));
  }
  databasePromise = new Promise((resolve, reject) => {
    const request = globalThis.indexedDB.open(DATABASE_NAME, DATABASE_VERSION);
    request.onupgradeneeded = () => {
      const database = request.result;
      if (database.objectStoreNames.contains(SAVE_STORE_NAME)) {
        database.deleteObjectStore(SAVE_STORE_NAME);
      }
      database.createObjectStore(SAVE_STORE_NAME, { keyPath: "id" });
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error ?? new Error("Failed to open IndexedDB"));
    request.onblocked = () => reject(new Error("IndexedDB upgrade is blocked by another tab"));
  }).catch((error) => {
    databasePromise = null;
    throw error;
  });
  return databasePromise;
}

function normalizeSlot(record) {
  if (!record || typeof record !== "object") return null;
  if (typeof record.id !== "string" || record.id.length === 0) return null;
  return {
    id: record.id,
    name: typeof record.name === "string" && record.name.length > 0
      ? record.name
      : "Untitled World",
    createdAt: Number.isFinite(Number(record.createdAt))
      ? Number(record.createdAt)
      : 0,
    newWorldType: typeof record.newWorldType === "string" && record.newWorldType.length > 0
      ? record.newWorldType
      : null,
    newWorldHeight: Number.isSafeInteger(Number(record.newWorldHeight))
      ? Number(record.newWorldHeight)
      : null,
    payload: typeof record.payload === "string" ? record.payload : null,
  };
}

function makeSaveId() {
  if (typeof globalThis.crypto?.randomUUID === "function") {
    return globalThis.crypto.randomUUID();
  }
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 10)}`;
}

function slotActivityTime(slot) {
  const payload = parseSavePayload(slot.payload);
  return payload?.savedAt ?? slot.createdAt;
}

function parseSavePayload(text) {
  if (typeof text !== "string" || text.length === 0) return null;
  try {
    const payload = JSON.parse(text);
    const seed = Number(payload?.world?.seed);
    const worldType = payload?.world?.world_type;
    const height = Number(payload?.world?.height);
    const savedAt = Number(payload?.saved_at);
    const blockDeltas = payload?.block_deltas;
    if (payload?.version !== globalThis.mcSaveSchemaVersion ||
      !Number.isInteger(seed) || seed < 0 || seed > 0xffffffff ||
      typeof worldType !== "string" || worldType.length === 0 ||
      !Number.isSafeInteger(height) || height <= 0 ||
      !Array.isArray(blockDeltas)) {
      return null;
    }
    return {
      seed,
      worldType,
      height,
      savedAt: Number.isFinite(savedAt) ? savedAt : null,
      blockDeltaCount: blockDeltas.length,
    };
  } catch (_) {
    return null;
  }
}

async function listSaveSlots() {
  const database = await openDatabase();
  const transaction = database.transaction(SAVE_STORE_NAME, "readonly");
  const completed = transactionResult(transaction);
  const records = await requestResult(transaction.objectStore(SAVE_STORE_NAME).getAll());
  await completed;
  return records
    .map(normalizeSlot)
    .filter((slot) => slot !== null)
    .sort((left, right) => slotActivityTime(right) - slotActivityTime(left));
}

async function createSaveSlot(name, worldType, worldHeight) {
  const slot = {
    id: makeSaveId(),
    name: typeof name === "string" && name.trim().length > 0 ? name.trim() : "New World",
    createdAt: Date.now(),
    newWorldType: typeof worldType === "string" && worldType.length > 0 ? worldType : null,
    newWorldHeight: Number.isSafeInteger(worldHeight) ? worldHeight : null,
    payload: null,
  };
  const database = await openDatabase();
  const transaction = database.transaction(SAVE_STORE_NAME, "readwrite");
  const completed = transactionResult(transaction);
  await requestResult(transaction.objectStore(SAVE_STORE_NAME).add(slot));
  await completed;
  return slot;
}

async function deleteSaveSlot(slotId) {
  const database = await openDatabase();
  const transaction = database.transaction(SAVE_STORE_NAME, "readwrite");
  const completed = transactionResult(transaction);
  await requestResult(transaction.objectStore(SAVE_STORE_NAME).delete(slotId));
  await completed;
}

async function writeSavePayload(slotId, payload) {
  if (!parseSavePayload(payload)) {
    throw new Error("Refusing to persist an invalid Mooncraft save payload");
  }
  const database = await openDatabase();
  const transaction = database.transaction(SAVE_STORE_NAME, "readwrite");
  const store = transaction.objectStore(SAVE_STORE_NAME);
  let updatedSlot = null;
  const completed = transactionResult(transaction);
  const readRequest = store.get(slotId);
  readRequest.onerror = () => transaction.abort();
  readRequest.onsuccess = () => {
    const slot = normalizeSlot(readRequest.result);
    if (!slot) {
      transaction.abort();
      return;
    }
    updatedSlot = {
      ...slot,
      newWorldType: null,
      newWorldHeight: null,
      payload,
    };
    store.put(updatedSlot);
  };
  await completed;
  if (!updatedSlot) {
    throw new Error(`Save slot ${slotId} no longer exists`);
  }
  return updatedSlot;
}

function createSaveWriter(slotId) {
  let pending = Promise.resolve();
  return {
    enqueue(payload) {
      const write = pending.then(() => writeSavePayload(slotId, payload));
      pending = write.catch(() => undefined);
      return write;
    },
  };
}

export {
  createSaveSlot,
  createSaveWriter,
  deleteSaveSlot,
  listSaveSlots,
  parseSavePayload,
};
