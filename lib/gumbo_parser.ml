
type source_position = {
    line      : int;
    column    : int;
    offset    : int;
  }

external parse : string -> Gumbo_output.t = "ogumbo_parse"
