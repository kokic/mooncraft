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
        if payload.version == SAVE_SCHEMA_VERSION {
          Some(payload)
        } else {
          None
        }
      } catch {
        _ => None
      }
  }
}
