type t

type value =
  | Document    of Gumbo_doc.t
  | Element     of Gumbo_elem.t
  | Text        of Gumbo_text.t
  | CDATA       of Gumbo_text.t
  | Comment     of Gumbo_text.t
  | Whitespace  of Gumbo_text.t
  | Template    of Gumbo_elem.t

val parent                : t -> t option

val index_within_parent   : t -> int

val value                 : t -> value

val value_type_to_string  : value -> string

(* TODO: val parse_flags : t -> ? *)
