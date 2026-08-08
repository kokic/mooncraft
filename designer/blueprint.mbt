///|
/// Voxel structure blueprint: a palette-indexed 3D grid.
/// `cells` is a flat array indexed `(y * depth + z) * width + x`; a value of
/// `-1` means air. `palette` holds block base names, optionally suffixed with
/// `:state` (e.g. `"classic.oak_log:1"`).
pub struct Blueprint {
  name : String
  size : Array[Int]
  anchor : Array[Int]
  palette : Array[String]
  cells : Array[Int]
} derive(Debug, ToJson, FromJson)

///|
pub fn Blueprint::new(
  name : String,
  size : Array[Int],
  anchor : Array[Int],
  palette? : Array[String] = [],
) -> Blueprint {
  let width = size[0]
  let height = size[1]
  let depth = size[2]
  Blueprint::{
    name,
    size: size.copy(),
    anchor: anchor.copy(),
    palette: palette.copy(),
    cells: Array::make(width * height * depth, -1),
  }
}

///|
pub fn Blueprint::width(self : Blueprint) -> Int {
  self.size[0]
}

///|
pub fn Blueprint::height(self : Blueprint) -> Int {
  self.size[1]
}

///|
pub fn Blueprint::depth(self : Blueprint) -> Int {
  self.size[2]
}

///|
pub fn Blueprint::cell_index(self : Blueprint, x : Int, y : Int, z : Int) -> Int {
  (y * self.depth() + z) * self.width() + x
}

///|
pub fn Blueprint::cell(self : Blueprint, x : Int, y : Int, z : Int) -> Int {
  self.cells[self.cell_index(x, y, z)]
}

///|
pub fn Blueprint::set_cell(self : Blueprint, x : Int, y : Int, z : Int, v : Int) -> Unit {
  self.cells[self.cell_index(x, y, z)] = v
}

///|
/// Crop all-air margins, shifting the anchor into the new local space.
pub fn Blueprint::trim_empty(self : Blueprint) -> Blueprint {
  let mut min_x = self.width()
  let mut min_y = self.height()
  let mut min_z = self.depth()
  let mut max_x = -1
  let mut max_y = -1
  let mut max_z = -1
  for y in 0..<self.height() {
    for z in 0..<self.depth() {
      for x in 0..<self.width() {
        if self.cell(x, y, z) < 0 {
          continue
        }
        if x < min_x {
          min_x = x
        }
        if x > max_x {
          max_x = x
        }
        if y < min_y {
          min_y = y
        }
        if y > max_y {
          max_y = y
        }
        if z < min_z {
          min_z = z
        }
        if z > max_z {
          max_z = z
        }
      }
    }
  }
  if max_x < 0 {
    return self
  }
  let trimmed = Blueprint::new(
    self.name,
    [max_x - min_x + 1, max_y - min_y + 1, max_z - min_z + 1],
    [
      self.anchor[0] - min_x,
      self.anchor[1] - min_y,
      self.anchor[2] - min_z,
    ],
    palette=self.palette.copy(),
  )
  for y in min_y..<=max_y {
    for z in min_z..<=max_z {
      for x in min_x..<=max_x {
        let v = self.cell(x, y, z)
        if v >= 0 {
          trimmed.set_cell(x - min_x, y - min_y, z - min_z, v)
        }
      }
    }
  }
  trimmed
}

///|
pub fn Blueprint::encode(self : Blueprint) -> String {
  self.to_json().stringify()
}

///|
pub fn Blueprint::decode(text : String) -> Blueprint? {
  try @json.parse(text) catch {
    _ => None
  } noraise {
    root =>
      try {
        let bp : Blueprint = @json.from_json(root)
        guard bp.size.length() == 3 && bp.anchor.length() == 3 else { None }
        guard bp.cells.length() == bp.width() * bp.height() * bp.depth() else {
          None
        }
        Some(bp)
      } catch {
        _ => None
      }
  }
}
