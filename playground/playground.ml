

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

let () =
  let output = Gumbo.parse doc |> Gumbo_output.document in
  
  print_endline ("name: " ^ (Gumbo_doc.name output));
  print_endline ("pub:  " ^ (Gumbo_doc.public_identifier output));
  print_endline ("sys:  " ^ (Gumbo_doc.system_identifier output));

  ()

