type t

type value =
  | Document    of Gumbo_doc.t
  | Element     of Gumbo_elem.t
  | Text        of Gumbo_text.t
  | CDATA       of Gumbo_text.t
  | Comment     of Gumbo_text.t
  | Whitespace  of Gumbo_text.t
  | Template    of Gumbo_elem.t

external parent : t -> t option = "ogumbo_node_parent"

external index_within_parent : t -> int = "ogumbo_node_index"

external value : t -> value = "ogumbo_node_value"

let value_type_to_string = function
  | Document _    -> "Document"
  | Element _     -> "Element"
  | Text _        -> "Text"
  | CDATA _       -> "CDATA"
  | Comment _     -> "Comment"
  | Whitespace _  -> "Whitespace"
  | Template _    -> "Template"
