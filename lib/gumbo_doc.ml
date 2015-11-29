type t

external has_doctype         : t -> bool    = "ogumbo_document_has_doctype"
external name                : t -> string  = "ogumbo_document_name"
external public_identifier   : t -> string  = "ogumbo_document_public_identifier"
external system_identifier   : t -> string  = "ogumbo_document_system_identifier"
