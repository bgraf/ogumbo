
module Attribute : sig
  type t
end

module Source : sig
  type pos = {
      line    : int;
      column  : int;
      offset  : int;
    }
end

module Text : sig
  type t
end

module Tag : sig
  type t

  type namespace = 
    | HTML
    | SVG
    | MathML

  val namespace_to_string : namespace -> string
end

module rec Document : sig
  type t

  val has_doctype       : t -> bool
  val name              : t -> string
  val public_identifier : t -> string
  val system_identifier : t -> string
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

  val parent : t -> t option 
  val index_within_parent : t -> int
  val value : t -> value 
  (* TODO: val parse_flags : t -> ? *)
end 


module Output : sig
  type t

  val document  : t -> Document.t
  val root      : t -> Node.t
end


module Parser : sig
  val parse : string -> Output.t
end
