(* 
 * Ogumbo - OCaml wrapper for the Gumbo HTML5 parser.
 *
 * Copyright (C) 2015 Benjamin Graf (bgraf@uni-osnabrueck.de) 
 *
 * License: MIT, see LICENSE
 *)

(** Ocaml bindings for the Gumbo HTML5 parser library. 
    
    @see <https://github.com/google/gumbo-parser> The gumbo-parser repository. *)

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

(** Content, whitespace and comments. *)
module Text : sig
  (** Represents text in the source document. 
      This can be whitespace, content or comments. *)
  type t

  (** [text txt] returns the content of [txt]. *)
  val text          : t -> string

  (** [original_text txt] returns the content of [txt] as it appeared in the
      document. *)
  val original_text : t -> string

  (** [start_pos txt] returns the start position of [txt] in the
      source document. *)
  val start_pos     : t -> Source.pos
end

(** Tag. *)
module Tag : sig
  (** Represents a HTML tag. *)
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

  (** Represents a tag namespace. *)
  type namespace = 
    | HTML
    | SVG
    | MathML


  (** [to_string tag] returns the lowercase string representation of [tag]. *)
  val to_string : t -> string

  (** [of_string s] returns the tag of name [s].
      If the string does not identify a specific tag the [Unknown] tag
      is returned. *)
  val of_string : string -> t

  (** [namespace_to_string ns] returns a string representation for the
      namespace [ns]. *)
  val namespace_to_string : namespace -> string
end

(** Doctypes. *)
module rec Document : sig
  (** The document. *)
  type t

  (** [has_doctype] returns whether this document has a doctype. *)
  val has_doctype       : t -> bool

  (** If a doctype is present [name doc] will return the doctype of [doc].
      Otherwise this will be the empty string. *)
  val name              : t -> string

  (** If a public identifier is present [public_identifier doc] 
      will return the public identifier of [doc].
      Otherwise this will be the empty string. *)
  val public_identifier : t -> string

  (** If a system identifier is present [system_identifier doc] 
      will return the public identifier of [doc].
      Otherwise this will be the empty string. *)
  val system_identifier : t -> string

  (** [children doc] will return a list of children of [doc].
      In the case that a whole HTML document was parsed,
      this will be just one node that can also be obtained
      by calling {!Output.root}. *)
  val children          : t -> Node.t list
end

(** A tag associated with child nodes and attributes. *)
and Element : sig
  (** Representation of an element. *)
  type t

  (** [tag elem] returns the tag of [elem]. *)
  val tag               : t -> Tag.t

  (** [namespace elem] returns the namespace of [elem]. *)
  val namespace         : t -> Tag.namespace

  (** [original_tag elem] returns the string that indicated the tag
      of [elem] as it appeared in the source document. *)
  val original_tag      : t -> string

  (** [original_end_tag elem] returns the string that indicated the end tag
      of [elem] as it appeared in the source document. 
      In the case of an ill-formed document, the parser may insert
      end tags.
      This will result in the empty string being returned. *)
  val original_end_tag  : t -> string

  (** [start_pos elem] returns the start position of [elem]. *)
  val start_pos         : t -> Source.pos

  (** [end_pos elem] returns the end position of [elem]. *)
  val end_pos           : t -> Source.pos

  (** [children elem] returns the list of child nodes of [elem]. *)
  val children          : t -> Node.t list

  (** [attributes elem] returns the list of attributes of [elem]. *)
  val attributes        : t -> Attribute.t list

  (** [attribute elem name] returns [Some(attr)] in case that an attribute
      [name] is present and [None] otherwise. *)
  val attribute         : t -> string -> Attribute.t option
end

(** A node in the parse tree. *)
and  Node : sig
  (** Representation of a node. *)
  type t

  (** Value contained in a node. *)
  type value =
    | Document    of Document.t
    | Element     of Element.t
    | Text        of Text.t
    | CDATA       of Text.t
    | Comment     of Text.t
    | Whitespace  of Text.t
    | Template    of Element.t

  (** [parent node] will return [Some(parent_node)] in case that [node]
      has a parent and [None] otherwise.

      Except for the document node obtained by calling {!Output.document_node}
      all nodes have parents. *)
  val parent : t -> t option 

  (** [index_within_parent node] returns the index of [node] within its
      parent node's children.
      Indices are zero-based. *)
  val index_within_parent : t -> int

  (** [value node] returns the [node]'s content. *)
  val value : t -> value 

  (** [parse_flags node] returns the [node]'s parse flags. *)
  val parse_flags : t -> Parseflags.t
end 

(** Parser output. *)
module Output : sig
  (** Parser output. *)
  type t

  (** [document out] returns the document node's content. *)
  val document      : t -> Document.t

  (** [document_node out] returns the document node.
      Usually this node will be the parent of the root node obtained
      using {!root}. *)
  val document_node : t -> Node.t

  (** [root out] returns the root node of the document. *)
  val root          : t -> Node.t
end

(** Parser entry points. *)
module Parser : sig
  (** [parse source] will parse and return a parse tree from the given [source]. *)
  val parse : string -> Output.t
end
