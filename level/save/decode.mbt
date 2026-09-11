///|
/// Decode only the current save schema. Older save versions are intentionally
/// unsupported because their IndexedDB store is discarded during upgrade.
pub fn decode_save_payload(text : String) -> SavePayload? {
  try @json.parse(text) catch {
    _ => None
  } noraise {
    root =>
      try {
        let payload : SavePayload = @json.from_json(root)
        guard payload.version == SAVE_SCHEMA_VERSION else { None }
        Some(payload)
      } catch {
        _ => None
      }
  }
}
