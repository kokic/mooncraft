///|
/// Errors raised while parsing or compiling glTF assets.
///
/// Each variant carries the payload needed to report the failure:
/// - `InvalidGlb` — the GLB container has a bad magic, version, or missing JSON
///   chunk (the message describes the exact problem).
/// - `UnsupportedAccessorType` — a glTF accessor `type` string is not
///   SCALAR/VEC2/VEC3/VEC4.
/// - `UnsupportedComponentType` — a glTF `componentType` integer is not one of
///   the supported WebGL constants.
/// - `ShaderCompileFailed` / `ProgramLinkFailed` — the WebGL shader compiler or
///   linker rejected the shader sources (the log is the GPU driver's message).
pub suberror GltfError {
  InvalidGlb(String)
  UnsupportedAccessorType(String)
  UnsupportedComponentType(Int)
  ShaderCompileFailed(String)
  ProgramLinkFailed(String)
}

///|
/// The human-readable message for this error.
pub fn GltfError::message(self : GltfError) -> String {
  match self {
    InvalidGlb(message) => message
    UnsupportedAccessorType(type_name) =>
      "unsupported accessor type: \{type_name}"
    UnsupportedComponentType(component_type) =>
      "unsupported component type: \{component_type}"
    ShaderCompileFailed(log) => "shader compile: \{log}"
    ProgramLinkFailed(log) => "program link: \{log}"
  }
}
