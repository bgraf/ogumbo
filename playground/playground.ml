

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

let () =
  let out = Parser.parse doc in
  let root = Output.root out in

  match Node.value root with
  | Node.Element elem -> begin
      elem
      |> Element.namespace
      |> Tag.namespace_to_string
      |> Printf.printf "namespace = %s\n";

      elem
      |> Element.original_tag
      |> Printf.printf "original_tag = '%s'\n";

      elem
      |> Element.children
      |> List.length
      |> Printf.printf "num children = %d\n";

      elem
      |> Element.children
      |> List.iter (fun child_node -> match Node.value child_node with
                    | Node.Element elem -> 
                        elem |> Element.original_tag |> Printf.printf "  child-tag: %s\n"
                    | _  -> ())
    end
  | _ -> print_endline "not an element.."
