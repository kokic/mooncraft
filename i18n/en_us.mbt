///|
pub let item_display_names : @hashmap.HashMap[String, String] = @hashmap.HashMap([
    ("grass", "Grass Block"),
    ("sandstone_carved", "Chiseled Sandstone"),
    ("sandstone_smooth", "Smooth Sandstone"),
    ("tnt", "TNT"),
  ],
)

///|
fn capitalize_first(s : String) -> String {
  let length = s.length()
  guard !(length == 0) else { s }
  guard !(length == 1) else { s.to_upper() }
  (s[0:1].to_upper() + s[1:]).to_owned()
}

///|
fn capitalize_spaces_style(s : StringView) -> String {
  s.split("_").map(v => capitalize_first(v.to_owned())).join(" ")
}

///|
fn humanize_name(name : String) -> String {
  match name {
    s if s.has_prefix("classic.") =>
      capitalize_spaces_style(name[8:]) + " (Classic)"
    s if s.has_prefix("pre-classic.") =>
      capitalize_spaces_style(name[12:]) + " (pre-Classic)"
    _ => capitalize_spaces_style(name)
  }
}

///|
/// Resolve display name from the map, falling back to a humanized name.
pub fn item_display_name(name : String) -> String {
  item_display_names.get(name).unwrap_or_else(() => humanize_name(name))
}
