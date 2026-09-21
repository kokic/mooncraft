///|
fn GltfRenderer::finish_asset(
  self : GltfRenderer,
  url : String,
  asset : GltfAsset,
) -> Unit {
  guard self.assets.get(url) is Some(Loading(callbacks)) else { () }
  self.assets[url] = Ready(asset)
  callbacks.each(callback => callback(asset))
}

///|
fn GltfRenderer::fail_asset(
  self : GltfRenderer,
  url : String,
  message : String,
) -> Unit {
  self.assets[url] = Failed
  log_gltf_error("failed to load \{url}: \{message}")
}

///|
extern "js" fn log_gltf_error(message : String) -> Unit =
  #| (message) => console.error(`[gltf] ${message}`)

///|
fn GltfRenderer::load_asset(
  self : GltfRenderer,
  url : String,
  on_load : (GltfAsset) -> Unit,
) -> Unit {
  let absolute_url = absolute_asset_url(url)
  match self.assets.get(absolute_url) {
    Some(Ready(asset)) => on_load(asset)
    Some(Loading(callbacks)) => callbacks.push(on_load)
    Some(Failed) => ()
    None => {
      self.assets[absolute_url] = Loading([on_load])
      fetch_array_buffer(
        absolute_url,
        buffer => self.decode_asset_response(absolute_url, buffer),
        message => self.fail_asset(absolute_url, message),
      )
    }
  }
}

///|
fn GltfRenderer::decode_asset_response(
  self : GltfRenderer,
  url : String,
  buffer : @ffi.ArrayBuffer,
) -> Unit {
  let (json_text, glb_bin) = decode_glb_or_json_text(buffer) catch {
    error => {
      self.fail_asset(url, error.message())
      return
    }
  }
  try @json.parse(json_text) catch {
    error => self.fail_asset(url, error.to_string())
  } noraise {
    root => self.load_asset_buffers(url, root, glb_bin)
  }
}

///|
fn GltfRenderer::load_asset_buffers(
  self : GltfRenderer,
  url : String,
  root : Json,
  glb_bin : @ffi.ArrayBuffer?,
) -> Unit {
  load_gltf_buffers(
    url,
    root,
    glb_bin,
    buffers => {
      let build = GltfAssetBuild::{ renderer: self, url, root, buffers, }
      build.complete()
    },
    message => self.fail_asset(url, message),
  )
}
