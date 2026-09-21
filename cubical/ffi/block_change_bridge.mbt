///|
pub extern "js" fn notify_block_changed(
  wx : Int,
  wy : Int,
  wz : Int,
  id : UInt,
) -> Unit =
  #| (wx, wy, wz, id) => {
  #|   const callback = globalThis.mcOnBlockChanged;
  #|   if (typeof callback === "function") {
  #|     callback(wx, wy, wz, id);
  #|   }
  #| }
