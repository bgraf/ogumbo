open OUnit2


let doc_html4 = 
  "<!DOCTYPE HTML PUBLIC 
      \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">
   <html></html>"

let doc_html5 =
  "<!DOCTYPE html><html></html>"

let doc_notype =
  "<html></html>"
  

let test_document_doctype ctxt =
  List.iter (fun source ->
    let name = Gumbo_parser.parse source
               |> Gumbo_output.document
               |> Gumbo_doc.name in
    assert_equal name "html")
  [doc_html4; doc_html5]


let test_document_empty_doctype ctxt =
  let doc = 
    Gumbo_parser.parse doc_notype
    |> Gumbo_output.document in
  let name = Gumbo_doc.name doc in
  
  assert_equal name "";
  assert_bool "has_doctype is false" (Gumbo_doc.has_doctype doc |> not)


let test_document_public_identifier ctxt =
  let pub_id = 
    Gumbo_parser.parse doc_html4
    |> Gumbo_output.document
    |> Gumbo_doc.public_identifier
  in
  assert_equal "-//W3C//DTD HTML 4.01//EN" pub_id
    

let test_document_system_identifier ctxt =
  let sys_id = 
    Gumbo_parser.parse doc_html4
    |> Gumbo_output.document
    |> Gumbo_doc.public_identifier
  in
  assert_equal sys_id "-//W3C//DTD HTML 4.01//EN"


let document_suite = "Test Document" >::: [
    "Test Doctype"        >:: test_document_doctype
  ; "Test empty Doctype"  >:: test_document_empty_doctype
  ; "Test public identifier"  >:: test_document_public_identifier
  ; "Test system identifier"  >:: test_document_system_identifier
  ]


let suite = "Test Ogumbo" >::: [
    document_suite
  ]

let () =
  run_test_tt_main suite

