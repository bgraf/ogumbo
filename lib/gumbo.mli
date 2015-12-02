
module Parseflags : sig
  type t

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

  val is_set : t -> flag -> bool
end

module Source : sig
  type pos = {
      line    : int;
      column  : int;
      offset  : int;
    }
end

module Attribute : sig
  type t

  val namespace       : t -> unit
  val name            : t -> string
  val original_name   : t -> string
  val value           : t -> string
  val original_value  : t -> string
  val name_start      : t -> Source.pos
  val name_end        : t -> Source.pos
  val value_start     : t -> Source.pos
  val value_end       : t -> Source.pos
  val to_string       : t -> string
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
