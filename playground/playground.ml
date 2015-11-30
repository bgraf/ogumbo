

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
  let output = Gumbo.parse doc2 |> Gumbo_output.document in
  
  print_endline ("name: " ^ (Gumbo_doc.name output));
  print_endline ("pub:  " ^ (Gumbo_doc.public_identifier output));
  print_endline ("sys:  " ^ (Gumbo_doc.system_identifier output));

  ()

