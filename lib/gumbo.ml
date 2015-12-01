
module Attribute = struct
  type t
end

module Source = struct
  type pos = {
      line    : int;
      column  : int;
      offset  : int;
    }
end

module Text = struct
  type t
end

module Tag = struct
  type t

  type namespace = 
    | HTML
    | SVG
    | MathML

  let namespace_to_string = function
    | HTML    -> "HTML"
    | SVG     -> "SVG"
    | MathML  -> "MathML"
end

module rec Document : sig
  type t

  val has_doctype       : t -> bool
  val name              : t -> string
  val public_identifier : t -> string
  val system_identifier : t -> string
end = struct
  type t

  external has_doctype         : t -> bool    = "ogumbo_document_has_doctype"
  external name                : t -> string  = "ogumbo_document_name"
  external public_identifier   : t -> string  = "ogumbo_document_public_identifier"
  external system_identifier   : t -> string  = "ogumbo_document_system_identifier"
end

and Element : sig
  type t
  val tag               : t -> Tag.t
  val namespace         : t -> Tag.namespace
  val original_tag      : t -> string
  val original_end_tag  : t -> string
  val start_pos         : t -> Source.pos
  val end_pos           : t -> Source.pos
  val children          : t -> Node.t list
  val attributes        : t -> Attribute.t list
end = struct 
  type t
  external tag               : t -> Tag.t               = "ogumbo_elem_tag"
  external namespace         : t -> Tag.namespace       = "ogumbo_elem_namespace"
  external original_tag      : t -> string              = "ogumbo_elem_original_tag"
  external original_end_tag  : t -> string              = "ogumbo_elem_original_end_tag"
  external start_pos         : t -> Source.pos          = "ogumbo_elem_start_pos"
  external end_pos           : t -> Source.pos          = "ogumbo_elem_end_pos"
  external children          : t -> Node.t list         = "ogumbo_elem_children"
  external attributes        : t -> Attribute.t list    = "ogumbo_elem_attributes"
end

and  Node : sig
  type t

  type value =
    | Document    of Document.t
    | Element     of Element.t
    | Text        of Text.t
    | CDATA       of Text.t
    | Comment     of Text.t
    | Whitespace  of Text.t
    | Template    of Element.t

  val parent              : t -> t option 
  val index_within_parent : t -> int
  val value               : t -> value 

end = struct 
  type t

  type value =
    | Document    of Document.t
    | Element     of Element.t
    | Text        of Text.t
    | CDATA       of Text.t
    | Comment     of Text.t
    | Whitespace  of Text.t
    | Template    of Element.t

  external parent               : t -> t option = "ogumbo_node_parent"
  external index_within_parent  : t -> int      = "ogumbo_node_index"
  external value                : t -> value    = "ogumbo_node_value"

end

module Output = struct
  type t

  external document : t -> Document.t   = "ogumbo_output_document"
  external root     : t -> Node.t       = "ogumbo_output_root"
end


module Parser = struct
  type t

  external parse : string -> Output.t = "ogumbo_parse"
end
