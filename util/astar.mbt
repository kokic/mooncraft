///|
/// A weighted edge from the current node to `node`.
///
/// `cost` must be non-negative for A*'s optimality guarantee to hold.
pub(all) struct AStarNeighbor[Node] {
  node : Node
  cost : Double
} derive(Debug)

///|
pub fn[Node] AStarNeighbor::new(
  node : Node,
  cost : Double,
) -> AStarNeighbor[Node] {
  { node, cost }
}

///|
/// The result of a successful A* search.
///
/// `nodes` includes both the start node and the goal node. `cost` is the total
/// path cost accumulated from neighbor edge costs.
pub(all) struct AStarPath[Node] {
  nodes : Array[Node]
  cost : Double
} derive(Debug)

///|
priv struct AStarOpenEntry[Node, Key] {
  node : Node
  key : Key
  g : Double
  f : Double
}

///|
fn[Node, Key] best_open_index(open : Array[AStarOpenEntry[Node, Key]]) -> Int? {
  guard !open.is_empty() else { None }
  let mut best = 0
  for i in 1..<open.length() {
    if open[i].f < open[best].f ||
      (open[i].f == open[best].f && open[i].g < open[best].g) {
      best = i
    }
  }
  Some(best)
}

///|
fn[Node, Key : Eq + Hash] reconstruct_path(
  goal_key : Key,
  nodes_by_key : Map[Key, Node],
  came_from : Map[Key, Key],
  total_cost : Double,
) -> AStarPath[Node] {
  let path = Array::new()
  let mut current = goal_key
  path.push(nodes_by_key[current])
  while came_from.contains(current) {
    current = came_from[current]
    path.push(nodes_by_key[current])
  }
  path.rev_in_place()
  { nodes: path, cost: total_cost }
}

///|
/// Find a cheapest path with the A* algorithm.
///
/// `Node` may be any value type used by the caller. The algorithm stores state
/// in maps keyed by `key(node)`, so only `Key` needs `Eq + Hash`.
///
/// `neighbors(node)` returns reachable next nodes and their edge costs.
/// `heuristic(node)` should estimate the remaining cost to the closest goal.
/// Use `0.0` for Dijkstra behavior.
pub fn[Node, Key : Eq + Hash] astar(
  start : Node,
  key~ : (Node) -> Key,
  is_goal~ : (Node) -> Bool,
  neighbors~ : (Node) -> Array[AStarNeighbor[Node]],
  heuristic~ : (Node) -> Double,
) -> AStarPath[Node]? {
  let start_key = key(start)
  let open = Array::new()
  let g_score : Map[Key, Double] = Map([])
  let came_from : Map[Key, Key] = Map([])
  let nodes_by_key : Map[Key, Node] = Map([])
  g_score[start_key] = 0.0
  nodes_by_key[start_key] = start
  open.push(AStarOpenEntry::{
    node: start,
    key: start_key,
    g: 0.0,
    f: heuristic(start),
  })
  while !open.is_empty() {
    guard best_open_index(open) is Some(index) else { return None }
    let entry = open.remove(index)
    match g_score.get(entry.key) {
      Some(best_g) => {
        guard entry.g == best_g else { continue }
        guard !is_goal(entry.node) else {
          return Some(
            reconstruct_path(entry.key, nodes_by_key, came_from, entry.g),
          )
        }
        for next in neighbors(entry.node) {
          let next_key = key(next.node)
          let tentative_g = entry.g + next.cost
          let should_update = match g_score.get(next_key) {
            Some(old_g) => tentative_g < old_g
            None => true
          }
          if should_update {
            came_from[next_key] = entry.key
            g_score[next_key] = tentative_g
            nodes_by_key[next_key] = next.node
            open.push({
              node: next.node,
              key: next_key,
              g: tentative_g,
              f: tentative_g + heuristic(next.node),
            })
          }
        }
      }
      None => ()
    }
  }
  None
}
