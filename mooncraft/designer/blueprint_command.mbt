///|
/// A parsed blueprint authoring command. `kind` is `"open"` or `"save"` and
/// `name` is the optional file name argument.
pub struct BlueprintCommand {
  kind : String
  name : String
}

///|
/// Parse a chat line as a `/open` or `/save` blueprint command. Returns `None`
/// when the text is not a blueprint command. Only the first argument is kept;
/// blueprint names are file names, not free-form text.
pub fn parse_blueprint_command(text : String) -> BlueprintCommand? {
  let tokens = text.trim().split(" ").filter(t => !t.is_empty()).to_array()
  match tokens {
    ["/open"] => Some({ kind: "open", name: "", })
    ["/open", name] => Some({ kind: "open", name: name.to_owned(), })
    ["/save"] => Some({ kind: "save", name: "", })
    ["/save", name] => Some({ kind: "save", name: name.to_owned(), })
    _ => None
  }
}
