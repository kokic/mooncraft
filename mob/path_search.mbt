///|
const MAX_PATH_SEARCH_EXPANSIONS : Int = 4096

///|
priv struct SearchOpenEntry {
  node : PathNode
  key : String
  cost : Double
  priority : Double
}

///|
priv enum PathSearchResult {
  InProgress
  Found(Array[PathNode])
  Unreachable
}

///|
priv struct PathSearch {
  chunk_map : @hashmap.HashMap[String, Array[UInt]]
  size : Int
  goal_wx : Int
  goal_wz : Int
  open : Array[SearchOpenEntry]
  costs : @hashmap.HashMap[String, Double]
  parents : @hashmap.HashMap[String, String]
  nodes : @hashmap.HashMap[String, PathNode]
  mut expanded : Int
}

///|
fn PathSearch::new(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  start_wx : Int,
  start_wy : Int,
  start_wz : Int,
  goal_wx : Int,
  goal_wz : Int,
) -> PathSearch {
  let start = PathNode::{ wx: start_wx, wy: start_wy, wz: start_wz }
  let key = pos_key(start_wx, start_wy, start_wz)
  let open = [
    {
      node: start,
      key,
      cost: 0.0,
      priority: ((start_wx - goal_wx).abs() + (start_wz - goal_wz).abs()).to_double(),
    },
  ]
  let costs : @hashmap.HashMap[String, Double] = @hashmap.HashMap([])
  costs[key] = 0.0
  let nodes : @hashmap.HashMap[String, PathNode] = @hashmap.HashMap([])
  nodes[key] = start
  {
    chunk_map,
    size,
    goal_wx,
    goal_wz,
    open,
    costs,
    parents: @hashmap.HashMap([]),
    nodes,
    expanded: 0,
  }
}

///|
fn PathSearch::best_open_index(self : PathSearch) -> Int? {
  guard !self.open.is_empty() else { None }
  let mut best = 0
  for index in 1..<self.open.length() {
    let candidate = self.open[index]
    let current = self.open[best]
    if candidate.priority < current.priority ||
      (candidate.priority == current.priority && candidate.cost < current.cost) {
      best = index
    }
  }
  Some(best)
}

///|
fn PathSearch::is_goal(self : PathSearch, node : PathNode) -> Bool {
  node.wx == self.goal_wx && node.wz == self.goal_wz
}

///|
fn PathSearch::heuristic(self : PathSearch, node : PathNode) -> Double {
  ((node.wx - self.goal_wx).abs() + (node.wz - self.goal_wz).abs()).to_double()
}

///|
fn PathSearch::neighbors(
  self : PathSearch,
  node : PathNode,
) -> Array[(PathNode, Double)] {
  let neighbors = []
  for direction in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
    let (dx, dz) = direction
    let wx = node.wx + dx
    let wz = node.wz + dz
    for step in [(node.wy, 1.0), (node.wy + 1, 1.5), (node.wy - 1, 1.2)] {
      let (wy, cost) = step
      guard is_walkable(self.chunk_map, self.size, wx, wy, wz) else { continue }
      neighbors.push((PathNode::{ wx, wy, wz }, cost))
    }
  }
  neighbors
}

///|
fn PathSearch::reconstruct(
  self : PathSearch,
  goal_key : String,
) -> Array[PathNode] {
  let path = [self.nodes[goal_key]]
  let mut key = goal_key
  while self.parents.contains(key) {
    key = self.parents[key]
    path.push(self.nodes[key])
  }
  path.rev_in_place()
  path
}

///|
fn PathSearch::advance(self : PathSearch, budget : Int) -> PathSearchResult {
  for _ in 0..<budget {
    guard self.expanded < MAX_PATH_SEARCH_EXPANSIONS else { return Unreachable }
    guard self.best_open_index() is Some(index) else { return Unreachable }
    let entry = self.open.remove(index)
    guard self.costs.get(entry.key) is Some(best_cost) else { continue }
    guard entry.cost == best_cost else { continue }
    self.expanded += 1
    guard !self.is_goal(entry.node) else {
      return Found(self.reconstruct(entry.key))
    }
    for neighbor in self.neighbors(entry.node) {
      let (next, step_cost) = neighbor
      let key = pos_key(next.wx, next.wy, next.wz)
      let cost = entry.cost + step_cost
      let should_update = match self.costs.get(key) {
        Some(previous) => cost < previous
        None => true
      }
      guard should_update else { continue }
      self.parents[key] = entry.key
      self.costs[key] = cost
      self.nodes[key] = next
      self.open.push({
        node: next,
        key,
        cost,
        priority: cost + self.heuristic(next),
      })
    }
  }
  if self.open.is_empty() {
    Unreachable
  } else {
    InProgress
  }
}
