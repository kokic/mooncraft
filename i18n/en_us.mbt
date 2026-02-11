///|
pub let item_display_names : Map[String, String] = {
  "grass": "Grass Block",
  "sandstone_carved": "Chiseled Sandstone",
  "sandstone_smooth": "Smooth Sandstone",
  "tnt": "TNT",
}

///|
fn capitalize_first(s : String) -> String {
  let length = s.length()
  guard !(length == 0) else { s }
  guard !(length == 1) else { s.to_upper() }
  try! (s[0:1].to_upper() + s[1:]).to_string()
}

///|
fn capitalize_spaces_style(s : StringView) -> String {
  s.split("_").map(v => capitalize_first(v.to_string())).join(" ")
}

///|
fn humanize_name(name : String) -> String {
  match name {
    s if s.has_prefix("classic.") =>
      capitalize_spaces_style(try! name[8:]) + " (Classic)"
    s if s.has_prefix("pre-classic.") =>
      capitalize_spaces_style(try! name[12:]) + " (pre-Classic)"
    _ => capitalize_spaces_style(name)
  }
}

///|
/// Resolve display name from the map, falling back to a humanized name.
pub fn item_display_name(name : String) -> String {
  match item_display_names.get(name) {
    Some(v) => v
    None => humanize_name(name)
  }
}
