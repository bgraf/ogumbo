

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
  

let () =
  let out = Gumbo.parse doc in
  let root  = Gumbo_output.root out in

  Gumbo_node.value root
  |> Gumbo_node.value_type_to_string
  |> print_endline

