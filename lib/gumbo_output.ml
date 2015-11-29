type t

external document : t -> Gumbo_doc.t  = "ogumbo_output_document"
external root     : t -> Gumbo_node.t = "ogumbo_output_root"
