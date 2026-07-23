///|
struct PathNode {
  wx : Int
  wy : Int
  wz : Int
} derive(Debug)

///|
fn is_solid_floor(long_id : UInt) -> Bool {
  guard long_id != @block.AIR_LONG_ID else { false }
  @block.lookup_by_long_id(long_id)
  .map(fn(block) {
    guard !block.is_water() else { false }
    match block.shape {
      @block.Shape::Air => false
      _ => true
    }
  })
  .unwrap_or(false)
}

///|
fn is_passable(long_id : UInt) -> Bool {
  guard long_id == @block.AIR_LONG_ID else {
    @block.lookup_by_long_id(long_id)
    .map(fn(block) { block.is_water() })
    .unwrap_or(false)
  }
  true
}

///|
fn is_walkable(
  chunk_map : @ffi.JsValue,
  size : Int,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Bool {
  let floor = @level.get_block_id(chunk_map, size, wx, wy - 1, wz)
  let feet = @level.get_block_id(chunk_map, size, wx, wy, wz)
  let head = @level.get_block_id(chunk_map, size, wx, wy + 1, wz)
  floor.map(is_solid_floor).unwrap_or(false) &&
  feet.map(is_passable).unwrap_or(false) &&
  head.map(is_passable).unwrap_or(false)
}

///|
fn pos_key(wx : Int, wy : Int, wz : Int) -> String {
  "\{wx},\{wy},\{wz}"
}

///|
/// Find a path from (start_wx, start_wz) to (goal_wx, goal_wz) using A* search
/// on the block grid. The Y level adapts via step-up and step-down neighbors.
/// Returns a list of waypoints including start, or None if no path exists.
pub fn find_path(
  chunk_map : @ffi.JsValue,
  size : Int,
  start_wx : Int,
  start_wy : Int,
  start_wz : Int,
  goal_wx : Int,
  goal_wz : Int,
) -> Array[PathNode]? {
  let start = PathNode::{ wx: start_wx, wy: start_wy, wz: start_wz }
  let dxs = [1, -1, 0, 0]
  let dzs = [0, 0, 1, -1]
  match
    @util.astar(
      start,
      key=fn(node : PathNode) -> String { pos_key(node.wx, node.wy, node.wz) },
      is_goal=fn(node : PathNode) -> Bool {
        node.wx == goal_wx && node.wz == goal_wz
      },
      neighbors=fn(node : PathNode) -> Array[@util.AStarNeighbor[PathNode]] {
        let out : Array[@util.AStarNeighbor[PathNode]] = []
        for i in 0..<4 {
          let dx = dxs[i]
          let dz = dzs[i]
          let nx = node.wx + dx
          let nz = node.wz + dz
          if is_walkable(chunk_map, size, nx, node.wy, nz) {
            out.push(
              @util.AStarNeighbor::new(
                PathNode::{ wx: nx, wy: node.wy, wz: nz },
                1.0,
              ),
            )
          }
          if is_walkable(chunk_map, size, nx, node.wy + 1, nz) {
            out.push(
              @util.AStarNeighbor::new(
                PathNode::{ wx: nx, wy: node.wy + 1, wz: nz },
                1.5,
              ),
            )
          }
          if is_walkable(chunk_map, size, nx, node.wy - 1, nz) {
            out.push(
              @util.AStarNeighbor::new(
                PathNode::{ wx: nx, wy: node.wy - 1, wz: nz },
                1.2,
              ),
            )
          }
        }
        out
      },
      heuristic=fn(node : PathNode) -> Double {
        ((node.wx - goal_wx).abs() + (node.wz - goal_wz).abs()).to_double()
      },
    ) {
    None => None
    Some(path) => Some(path.nodes)
  }
}

///|
pub fn path_nodes_to_arrays(nodes : Array[PathNode]) -> Array[Array[Int]] {
  nodes.map(fn(node : PathNode) -> Array[Int] { [node.wx, node.wy, node.wz] })
}
