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
  if name is "Flat" {
    WorldType::Flat
  } else if name is "Infinite" {
    WorldType::Infinite
  } else if name is "PreClassic" {
    WorldType::PreClassic
  } else if name is "Finite" {
    WorldType::Finite
  } else {
    fallback
  }
}
