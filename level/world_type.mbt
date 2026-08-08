///|
pub(all) enum WorldType {
  Flat
  Infinite
  PreClassic
  Finite
  Design
}

///|
pub fn world_type_name(kind : WorldType) -> String {
  match kind {
    WorldType::Flat => "Flat"
    WorldType::Infinite => "Infinite"
    WorldType::PreClassic => "PreClassic"
    WorldType::Finite => "Finite"
    WorldType::Design => "Design"
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
    "Design" => WorldType::Design
    _ => fallback
  }
}

///|
#export_name("getWorldTypeNames")
pub fn get_world_type_names() -> FixedArray[String] {
  ["Flat", "Infinite", "PreClassic", "Finite", "Design"]
}

///|
#export_name("defaultWorldTypeName")
pub fn default_world_type_name() -> String {
  get_world_type_names()[0]
}
