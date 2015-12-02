
(** Ocaml bindings for the Gumbo HTML5 parser library. *)

(** Parse flags associated with a node. *)
module Parseflags : sig
  (** Type representing a set of flags. *)
  type t

  (** Possible flags. *)
  type flag = 
    | Normal
    | By_parser
    | Implicit_end_tag
    | Implied
    | Converted_from_end_tag
    | From_isindex
    | From_image
    | Reconstructed_formatting_element
    | Adoption_agency_cloned
    | Adoption_agency_moved
    | Foster_parented

  (** Returns whether a [flag] is set in the given parse flags. *)
  val is_set : t -> flag -> bool
end

(** Provides source position. *)
module Source : sig
  (** Position in the source string. *)
  type pos = {
      line    : int; 
      column  : int; 
      offset  : int; 
    }
end

(** Html attributes. *)
module Attribute : sig
  (** Type representing an attribute. *)
  type t

  (** Attribute namespaces. *)
  type namespace =
    | None
    | XLINK
    | XML
    | XMLNS

  (** [namespace attr] returns the namespace of [attr]. *)
  val namespace       : t -> namespace

  (** [name attr] returns the normalized (lowercase) name of [attr]. *)
  val name            : t -> string

  (** [original_name] returns the name of [attr] as it
      appeared in the source buffer. *)
  val original_name   : t -> string

  (** [value attr] returns the value of [attr]. *)
  val value           : t -> string

  (** [original_value attr] returns the value of [attr] as it
      appeared in the source buffer, including quotation-marks. *)
  val original_value  : t -> string

  (** [name_start attr] returns the start position of [attr]'s name
      in the source buffer. *)
  val name_start      : t -> Source.pos

  (** [name_end attr] returns the end position of [attr]'s name
      in the source buffer. *)
  val name_end        : t -> Source.pos

  (** [value_start attr] returns the start position of [attr]'s value
      in the source buffer. *)
  val value_start     : t -> Source.pos

  (** [value_end attr] returns the end position of [attr]'s value
      in the source buffer. *)
  val value_end       : t -> Source.pos

  (** [to_string attr] returns a string representation of the
      name-value-tuple represented by [attr].
      Given a name [foo] and key [bar] it will produce [foo="bar"]. *)
  val to_string       : t -> string

  (** Returns a string representation of the namespace variant. *)
  val namespace_to_string : namespace -> string
end

module Text : sig
  type t

  val text          : t -> string
  val original_text : t -> string
  val start_pos     : t -> Source.pos
end

module Tag : sig
  type t =
    | Html
    | Head
    | Title
    | Base
    | Link
    | Meta
    | Style
    | Script
    | Noscript
    | Template
    | Body
    | Article
    | Section
    | Nav
    | Aside
    | H1
    | H2
    | H3
    | H4
    | H5
    | H6
    | Hgroup
    | Header
    | Footer
    | Address
    | P
    | Hr
    | Pre
    | Blockquote
    | Ol
    | Ul
    | Li
    | Dl
    | Dt
    | Dd
    | Figure
    | Figcaption
    | Main
    | Div
    | A
    | Em
    | Strong
    | Small
    | S
    | Cite
    | Q
    | Dfn
    | Abbr
    | Data
    | Time
    | Code
    | Var
    | Samp
    | Kbd
    | Sub
    | Sup
    | I
    | B
    | U
    | Mark
    | Ruby
    | Rt
    | Rp
    | Bdi
    | Bdo
    | Span
    | Br
    | Wbr
    | Ins
    | Del
    | Image
    | Img
    | Iframe
    | Embed
    | Object
    | Param
    | Video
    | Audio
    | Source
    | Track
    | Canvas
    | Map
    | Area
    | Math
    | Mi
    | Mo
    | Mn
    | Ms
    | Mtext
    | Mglyph
    | Malignmark
    | Annotation_xml
    | Svg
    | Foreignobject
    | Desc
    | Table
    | Caption
    | Colgroup
    | Col
    | Tbody
    | Thead
    | Tfoot
    | Tr
    | Td
    | Th
    | Form
    | Fieldset
    | Legend
    | Label
    | Input
    | Button
    | Select
    | Datalist
    | Optgroup
    | Option
    | Textarea
    | Keygen
    | Output
    | Progress
    | Meter
    | Details
    | Summary
    | Menu
    | Menuitem
    | Applet
    | Acronym
    | Bgsound
    | Dir
    | Frame
    | Frameset
    | Noframes
    | Isindex
    | Listing
    | Xmp
    | Nextid
    | Noembed
    | Plaintext
    | Rb
    | Strike
    | Basefont
    | Big
    | Blink
    | Center
    | Font
    | Marquee
    | Multicol
    | Nobr
    | Spacer
    | Tt
    | Rtc
    | Unknown

  type namespace = 
    | HTML
    | SVG
    | MathML

  val to_string : t -> string
  val of_string : string -> t

  val namespace_to_string : namespace -> string
end

module rec Document : sig
  type t

  val has_doctype       : t -> bool
  val name              : t -> string
  val public_identifier : t -> string
  val system_identifier : t -> string
  val children          : t -> Node.t list
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
  val attribute         : t -> string -> Attribute.t option
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
  val parse_flags : t -> Parseflags.t
end 


module Output : sig
  type t

  val document      : t -> Document.t
  val document_node : t -> Node.t
  val root          : t -> Node.t
end


module Parser : sig
  val parse : string -> Output.t
end
