

let doc = "
<!DOCTYPE html>
<html>
  <head>
    <title>hello world</title>
  </head>
  <body>
    <h1>Hello there!</h1>
    blabla
  </body>
  </html>
"

let doc2 = "
<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">
<html></html>
"
 
open Gumbo

let node_to_string node =
  match Node.value node with
  | Node.Element elem ->
      Element.tag elem
      |> Tag.to_string
      |> Printf.sprintf "Element[%s]"
  | Node.Template _   -> "Template[]"
  | Node.Text _       -> "Text[]"
  | Node.Whitespace _ -> "Whitespace[]"
  | Node.CDATA      _ -> "CDATA[]"
  | Node.Comment    _ -> "Comment[]"
  | Node.Document   _ -> "Document[]"

let rec print_doc ?(layer=0) node =
  let indent = String.make (layer*4) ' ' in

  node_to_string node
  |> Printf.printf "%s %s\n" indent;

  match Node.value node with
  | Node.Element elem ->
      elem
      |> Element.children 
      |> List.iter (print_doc ~layer:(layer+1))
  | _ -> ()




let () =
  let out = Parser.parse doc in
  let root = Output.root out in

  print_doc root
