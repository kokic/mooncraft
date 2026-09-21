///|
/// Decode only the current save schema. Older save versions are intentionally
/// unsupported because their IndexedDB store is discarded during upgrade.
pub fn decode_save_payload(text : String) -> SavePayload? {
  try {
    let payload : SavePayload = @json.from_json(@json.parse(text))
    guard payload.version == SAVE_SCHEMA_VERSION else { None }
    Some(payload)
  } catch {
    _ => None
  }
}

///|
/// Decode the summary a save slot needs without exposing the full payload.
pub fn decode_save_summary(text : String) -> SaveSummary? {
  guard decode_save_payload(text) is Some(payload) else { None }
  Some({
    seed: payload.world.seed,
    world_type: payload.world.world_type,
    height: payload.world.height,
    saved_at: payload.saved_at,
    block_delta_count: payload.block_deltas.length(),
  })
}
