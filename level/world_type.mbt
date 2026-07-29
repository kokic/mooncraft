///|
pub(all) enum WorldType {
  Flat
  Infinite
  PreClassic
  Finite
}

///|
pub fn world_type_name(kind : WorldType) -> String {
  match kind {
    WorldType::Flat => "Flat"
    WorldType::Infinite => "Infinite"
    WorldType::PreClassic => "PreClassic"
    WorldType::Finite => "Finite"
  }
}

///|
pub fn world_type_from_name(
  name : String,
  fallback? : WorldType = WorldType::PreClassic,
) -> WorldType {
  match name {
    "Flat" => WorldType::Flat
    "Infinite" => WorldType::Infinite
    "PreClassic" => WorldType::PreClassic
    "Finite" => WorldType::Finite
    _ => fallback
  }
}

///|
#export_name("getWorldTypeNames")
pub fn get_world_type_names() -> FixedArray[String] {
  ["Flat", "Infinite", "PreClassic", "Finite"]
}

///|
#export_name("defaultWorldTypeName")
pub fn default_world_type_name() -> String {
  get_world_type_names()[0]
}
