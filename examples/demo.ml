open Formulis

let listen_to_z old_val new_val =
  print_endline (Printf.sprintf "z changed from %d to %d" old_val new_val)

let () =
  let x = term 3 in
  (* Not actually an int, but a term that holds an int value. *)
  let y = term 5 in
  (* Same as above. *)
  let z = Int.(Term x +~ Term y) in
  (* z = x + y -> 3 + 5 = 8. *)
  Printf.printf "%d\n" (eval z);
  (* Gets the value "8". *)
  on_change z listen_to_z;
  set x 4;
  (* Change the value of the term x. *)
  Printf.printf "%d\n" (eval z)
  (* z = x + y -> 4 + 5 = "9" now. Everything is updated automatically. *)
