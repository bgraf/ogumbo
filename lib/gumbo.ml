
module Parseflags = struct
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

  external is_set : t -> flag -> bool = "ogumbo_parseflags_is_set"
end

module Source = struct
  type pos = {
      line    : int;
      column  : int;
      offset  : int;
    }
end

module Attribute = struct
  type t

  type namespace =
    | None
    | XLINK
    | XML
    | XMLNS

  external namespace : t -> namespace     = "ogumbo_attr_namespace"
  external name : t -> string             = "ogumbo_attr_name"
  external original_name : t -> string    = "ogumbo_attr_original_name"
  external value : t -> string            = "ogumbo_attr_value"
  external original_value : t -> string   = "ogumbo_attr_original_value"
  external name_start : t -> Source.pos   = "ogumbo_attr_name_start"
  external name_end : t -> Source.pos     = "ogumbo_attr_name_end"
  external value_start : t -> Source.pos  = "ogumbo_attr_value_start"
  external value_end : t -> Source.pos    = "ogumbo_attr_value_end"

  let to_string attr =
    Printf.sprintf "%s=\"%s\"" (name attr) (value attr)

  let namespace_to_string = function
    | None    -> "None"
    | XLINK   -> "XLINK"
    | XML     -> "XML"
    | XMLNS   -> "XMLNS"
end

module Text = struct
  type t

  external text          : t -> string      = "ogumbo_text_text"
  external original_text : t -> string      = "ogumbo_text_original_text"
  external start_pos     : t -> Source.pos  = "ogumbo_text_start_pos"
end

module Tag = struct
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

  external to_string : t -> string = "ogumbo_tag_to_string"
  external of_string : string -> t = "ogumbo_tag_of_string"

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
  val children          : t -> Node.t list
end = struct
  type t

  external has_doctype        : t -> bool    = "ogumbo_document_has_doctype"
  external name               : t -> string  = "ogumbo_document_name"
  external public_identifier  : t -> string  = "ogumbo_document_public_identifier"
  external system_identifier  : t -> string  = "ogumbo_document_system_identifier"
  external children           : t -> Node.t list = "ogumbo_document_children"
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
  external attribute         : t -> string -> Attribute.t option = "ogumbo_elem_attribute"
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
  val parse_flags         : t -> Parseflags.t
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
  external parse_flags          : t -> Parseflags.t = "ogumbo_node_parse_flags"
end

module Output = struct
  type t

  external document       : t -> Document.t   = "ogumbo_output_document"
  external document_node  : t -> Node.t       = "ogumbo_output_document_node"
  external root           : t -> Node.t       = "ogumbo_output_root"
end


module Parser = struct
  type t

  external parse : string -> Output.t = "ogumbo_parse"
end
