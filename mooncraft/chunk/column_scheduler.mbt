///|
/// Owns column residency, desired coverage, and generation scheduling.
priv struct ColumnScheduler {
  loaded_columns : @hashmap.HashMap[String, Bool]
  mut desired_columns : @hashmap.HashMap[String, Bool]
  mut desired_center_x : Int
  mut desired_center_z : Int
  mut has_desired_center : Bool
  queued_columns : @hashmap.HashMap[String, Bool]
  mut column_queue : Array[String]
  mut queue_head : Int
  mut active_column : @level.ChunkColumnGeneration?
}

///|
fn ColumnScheduler::new(
  loaded_columns : @hashmap.HashMap[String, Bool],
) -> ColumnScheduler {
  {
    loaded_columns,
    desired_columns: @hashmap.HashMap([]),
    desired_center_x: 0,
    desired_center_z: 0,
    has_desired_center: false,
    queued_columns: @hashmap.HashMap([]),
    column_queue: [],
    queue_head: 0,
    active_column: None,
  }
}

///|
fn ColumnScheduler::enqueue_column(self : ColumnScheduler, key : String) -> Unit {
  let is_active = self.active_column.map_or(false, generation => {
    generation.column_key() == key
  })
  guard !self.loaded_columns.contains(key) &&
    !self.queued_columns.contains(key) &&
    !is_active else {
    return
  }
  self.queued_columns[key] = true
  self.column_queue.push(key)
}

///|
fn ColumnScheduler::refresh_desired(
  self : ColumnScheduler,
  center_x : Int,
  center_z : Int,
  render_distance : Int,
) -> Unit {
  // Desired chunk keys only change when the player enters another column.
  // Avoid rebuilding the render-distance map and re-enqueuing keys every frame.
  if self.has_desired_center &&
    self.desired_center_x == center_x &&
    self.desired_center_z == center_z {
    return
  }
  self.has_desired_center = true
  self.desired_center_x = center_x
  self.desired_center_z = center_z
  self.desired_columns = @hashmap.HashMap([])
  for
    key in collect_render_column_keys(center_x, center_z, render_distance) {
    self.desired_columns[key] = true
    self.enqueue_column(key)
  }
}

///|
fn ColumnScheduler::take_queued_column(self : ColumnScheduler) -> String? {
  while self.queue_head < self.column_queue.length() {
    let key = self.column_queue[self.queue_head]
    self.queue_head = self.queue_head + 1
    self.queued_columns.remove(key)
    if self.loaded_columns.contains(key) || !self.desired_columns.contains(key) {
      continue
    }
    return Some(key)
  }
  self.column_queue = []
  self.queue_head = 0
  None
}
