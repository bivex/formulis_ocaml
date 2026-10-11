(* Port of test/source/formulis_test.cpp.

   The C++ suite uses Catch2; OCaml needs no framework for this size, so
   the familiar TEST_CASE/SECTION shape is kept with a tiny hand-rolled
   harness: every "check" bumps a counter and a failed suite exits 1. *)

open Formulis

module I = Formulis.Int
module B = Formulis.Bool

(* The C++ suite registers these with REGISTER_UNARY_PROC; here any
   function is a reactive operator via [map]. *)
let my_func (x : int) : int = (3 * x) + 1

let is_even (x : int) : bool = x mod 2 = 0

(* --- Harness --------------------------------------------------------- *)

let passed = ref 0
let failed = ref 0

let check what b =
  if b then incr passed
  else (
    incr failed;
    Printf.eprintf "FAILED: %s\n%!" what)

let check_int what (v : int) expected = check what (v = expected)
let check_bool what (v : bool) expected = check what (v = expected)

let tests : (string * (unit -> unit)) list =
  [ ( "simple terms / change from 2 to 3",
      fun () ->
        let x = term 2 in
        check_int "x == 2" (get x) 2;
        set x 3;
        check_int "x == 3" (get x) 3 );
    ( "simple terms / increment test",
      fun () ->
        let x = term 2 in
        check_int "x == 2" (get x) 2;
        I.incr x;
        check_int "x == 3" (get x) 3;
        (* C++ post-increment returns the previous value. *)
        let y = get x in
        I.incr x;
        check_int "y == 3" y 3;
        check_int "x == 4" (get x) 4 );
    ( "simple terms / decrement test",
      fun () ->
        let x = term 4 in
        check_int "x == 4" (get x) 4;
        I.decr x;
        check_int "x == 3" (get x) 3;
        let y = get x in
        I.decr x;
        check_int "y == 3" y 3;
        check_int "x == 2" (get x) 2 );
    ( "simple terms / += test",
      fun () ->
        let x = term 2 in
        check_int "x == 2" (get x) 2;
        I.(x += 2);
        check_int "x == 4" (get x) 4 );
    ( "simple terms / -= test",
      fun () ->
        let x = term 4 in
        check_int "x == 4" (get x) 4;
        I.(x -= 2);
        check_int "x == 2" (get x) 2 );
    ( "2 term formulas / basic formula [+]",
      fun () ->
        let x = term 2 and y = term 2 in
        let z = I.(Term x +~ Term y) in
        check_int "z == 4" (eval z) 4;
        set x 3;
        check_int "z == 5" (eval z) 5;
        set y 3;
        check_int "z == 6" (eval z) 6 );
    ( "2 term formulas / basic formula [+] and const",
      fun () ->
        let x = term 2 in
        let z = I.(Term x +~ Const 1) in
        check_int "z == 3" (eval z) 3;
        set x 3;
        check_int "z == 4" (eval z) 4;
        let w = I.(Const 1 +~ Term x) in
        check_int "w == 4" (eval w) 4;
        set x 4;
        check_int "w == 5" (eval w) 5 );
    ( "2 term formulas / basic formula [*]",
      fun () ->
        let x = term 2 and y = term 2 in
        let z = I.(Term x *~ Term y) in
        check_int "z == 4" (eval z) 4;
        set x 3;
        check_int "z == 6" (eval z) 6;
        set y 3;
        check_int "z == 9" (eval z) 9 );
    ( "2 term formulas / basic formula [/]",
      fun () ->
        let x = term 2 and y = term 2 in
        let z = I.(Term x /~ Term y) in
        check_int "z == 1" (eval z) 1;
        set x 3;
        check_int "z == 1" (eval z) 1;
        set y 4;
        check_int "z == 0" (eval z) 0 );
    ( "2 term formulas / basic formula [%]",
      fun () ->
        let x = term 2 and y = term 2 in
        let z = I.(Term x %~ Term y) in
        check_int "z == 0" (eval z) 0;
        set x 3;
        check_int "z == 1" (eval z) 1;
        set y 4;
        check_int "z == 3" (eval z) 3 );
    ( "3 term formulas / test formula creation and updating",
      fun () ->
        let x = term 2 and y = term 2 and z = term 2 in
        let w = I.(Term x +~ Term y +~ Term z) in
        check_int "w == 6" (eval w) 6;
        set x 3;
        check_int "w == 7" (eval w) 7;
        set y 3;
        check_int "w == 8" (eval w) 8;
        set z 3;
        check_int "w == 9" (eval w) 9 );
    ( "3 term formulas / different parenthesis",
      fun () ->
        let x = term 2 and y = term 2 and z = term 2 in
        let w = I.(Term x +~ (Term y +~ Term z)) in
        check_int "w == 6" (eval w) 6;
        set x 3;
        check_int "w == 7" (eval w) 7;
        set y 3;
        check_int "w == 8" (eval w) 8;
        set z 3;
        check_int "w == 9" (eval w) 9 );
    ( "4 term formulas / test formula creation and updating",
      fun () ->
        let x = term 2 and y = term 2 and z = term 2 and w = term 2 in
        let o = I.(Term x +~ Term y +~ Term z +~ Term w) in
        check_int "o == 8" (eval o) 8;
        set x 3;
        check_int "o == 9" (eval o) 9;
        set y 3;
        check_int "o == 10" (eval o) 10;
        set z 3;
        check_int "o == 11" (eval o) 11;
        set w 3;
        check_int "o == 12" (eval o) 12 );
    ( "4 term formulas / different parenthesis",
      fun () ->
        let x = term 2 and y = term 2 and z = term 2 and w = term 2 in
        let o = I.(Term x +~ Term y +~ (Term z +~ Term w)) in
        check_int "o == 8" (eval o) 8;
        set x 3;
        check_int "o == 9" (eval o) 9;
        set y 3;
        check_int "o == 10" (eval o) 10;
        set z 3;
        check_int "o == 11" (eval o) 11;
        set w 3;
        check_int "o == 12" (eval o) 12 );
    ( "constants in formulas / constant on the right updates",
      fun () ->
        let x = term 2 in
        let z = I.(Term x +~ Const 1) in
        check_int "z == 3" (eval z) 3;
        set x 5;
        check_int "z == 6" (eval z) 6 );
    ( "constants in formulas / constant on the left updates",
      fun () ->
        let x = term 2 in
        let z = I.(Const 10 -~ Term x) in
        check_int "z == 8" (eval z) 8;
        set x 4;
        check_int "z == 6" (eval z) 6 );
    ( "constants in formulas / multiple constants in one expression",
      fun () ->
        let x = term 1 in
        let z = I.(Term x +~ Const 1 +~ Const 2 +~ Const 3) in
        check_int "z == 7" (eval z) 7;
        set x 4;
        check_int "z == 10" (eval z) 10 );
    ( "constants in formulas / several formulas sharing one term",
      fun () ->
        let x = term 2 in
        let a = I.(Term x +~ Const 1) in
        let b = I.(Term x *~ Const 5) in
        let c = I.(Term x -~ Const 3) in
        check_int "a == 3" (eval a) 3;
        check_int "b == 10" (eval b) 10;
        check_int "c == -1" (eval c) (-1);
        set x 7;
        check_int "a == 8" (eval a) 8;
        check_int "b == 35" (eval b) 35;
        check_int "c == 4" (eval c) 4 );
    ( "constants in formulas / constants nested with parenthesis",
      fun () ->
        let a = term 2 and b = term 3 in
        let z = I.((Term a +~ Const 1) *~ (Term b +~ Const 2)) in
        check_int "z == 15" (eval z) 15;
        set a 1;
        check_int "z == 10" (eval z) 10;
        set b 4;
        check_int "z == 12" (eval z) 12 );
    ( "constants in formulas / term copies are independent",
      fun () ->
        let x = term 2 in
        (* C++ copies a term by value; here the copy is [term (get x)]. *)
        let y = term (get x) in
        check_int "y == 2" (get y) 2;
        let z = I.(Term x +~ Const 1) in
        set x 10;
        check_int "z == 11" (eval z) 11;
        check_int "y == 2" (get y) 2;
        I.incr x;
        check_int "z == 12" (eval z) 12;
        check_int "y == 2" (get y) 2 );
    ( "boolean operators / term && term",
      fun () ->
        let p = term true and q = term false in
        let b = B.(Term p &&~ Term q) in
        check_bool "b == false" (eval b) false;
        set q true;
        check_bool "b == true" (eval b) true;
        set p false;
        check_bool "b == false" (eval b) false );
    ( "boolean operators / term || term",
      fun () ->
        let p = term false and q = term false in
        let b = B.(Term p ||~ Term q) in
        check_bool "b == false" (eval b) false;
        set p true;
        check_bool "b == true" (eval b) true );
    ( "boolean operators / constant && term",
      fun () ->
        let x = term false in
        let b = B.(Const true &&~ Term x) in
        check_bool "b == false" (eval b) false;
        set x true;
        check_bool "b == true" (eval b) true );
    ( "boolean operators / term || constant",
      fun () ->
        let x = term true in
        let b = B.(Term x ||~ Const false) in
        check_bool "b == true" (eval b) true;
        set x false;
        check_bool "b == false" (eval b) false );
    ( "boolean operators / not term",
      fun () ->
        let x = term true in
        let b = B.not (Term x) in
        check_bool "b == false" (eval b) false;
        set x false;
        check_bool "b == true" (eval b) true );
    ( "boolean operators / not formula",
      fun () ->
        (* C++: !f where f = x - 2, i.e. "f is zero". *)
        let x = term 2 in
        let f = I.(Term x -~ Const 2) in
        let b = B.not (map (fun v -> v <> 0) f) in
        check_bool "b == true" (eval b) true;
        set x 5;
        check_bool "b == false" (eval b) false );
    ( "boolean operators / mixed formulas and constants",
      fun () ->
        (* C++: (x && y) || 0 with x.set(0), y.set(5), x.set(2) — y
           stays truthy, so the bool analogue keeps q true. *)
        let p = term true and q = term true in
        let b = B.((Term p &&~ Term q) ||~ Const false) in
        check_bool "b == true" (eval b) true;
        set p false;
        check_bool "b == false" (eval b) false;
        set q true;
        (* Value unchanged: the term itself does not even fire. *)
        check_bool "b == false" (eval b) false;
        set p true;
        check_bool "b == true" (eval b) true );
    ( "boolean operators / bool terms",
      fun () ->
        let p = term true and q = term false in
        let b = B.(Term p &&~ Term q) in
        check_bool "b == false" (eval b) false;
        set q true;
        check_bool "b == true" (eval b) true );
    ( "custom boolean operator / test creation of custom boolean unary op",
      fun () ->
        let x = term 4 in
        let z = map is_even (Term x) in
        check_bool "z == true" (eval z) true;
        set x 5;
        check_bool "z == false" (eval z) false );
    ( "unary operators / unary minus on term is reactive",
      fun () ->
        let x = term 5 in
        let z = I.neg (Term x) in
        check_int "z == -5" (eval z) (-5);
        set x (-7);
        check_int "z == 7" (eval z) 7 );
    ( "unary operators / unary plus on term is reactive",
      fun () ->
        let x = term 5 in
        let z = map (fun v -> v) (Term x) in
        check_int "z == 5" (eval z) 5;
        set x (-3);
        check_int "z == -3" (eval z) (-3) );
    ( "unary operators / unary minus on formula",
      fun () ->
        let x = term 5 in
        let f = I.(Term x *~ Const 2) in
        let z = I.neg f in
        check_int "z == -10" (eval z) (-10);
        set x 10;
        check_int "z == -20" (eval z) (-20) );
    ( "unary operators / unary minus on expression with constant",
      fun () ->
        let x = term 2 in
        let z = I.neg I.(Term x +~ Const 3) in
        check_int "z == -5" (eval z) (-5);
        set x 4;
        check_int "z == -7" (eval z) (-7) );
    ( "unary operators / bitwise not on term",
      fun () ->
        let x = term 0 in
        let z = I.bit_not (Term x) in
        check_int "z == -1" (eval z) (-1);
        set x 5;
        check_int "z == -6" (eval z) (-6) );
    ( "set from formula and term / set from formula takes its current value",
      fun () ->
        let x = term 1 and y = term 2 in
        let f = I.(Term x +~ Const 41) in
        set_from y f;
        check_int "y == 42" (get y) 42;
        set x 0;
        check_int "f == 41" (eval f) 41;
        check_int "y == 42" (get y) 42 );
    ( "set from formula and term / set from term takes its current value",
      fun () ->
        let a = term 5 and b = term 1 in
        set_from b (Term a);
        check_int "b == 5" (get b) 5;
        set a 9;
        check_int "b == 5" (get b) 5 );
    ( "on_change / fires for auto-bound formula",
      fun () ->
        let x = term 3 and y = term 5 in
        let z = I.(Term x +~ Term y) in
        let old_v = ref (-1) and new_v = ref (-1) in
        on_change z (fun o n ->
            old_v := o;
            new_v := n);
        set x 4;
        check_int "old_v == 8" !old_v 8;
        check_int "new_v == 9" !new_v 9;
        set y 6;
        check_int "old_v == 9" !old_v 9;
        check_int "new_v == 10" !new_v 10 );
    ( "on_change / fires when registered on a copy of a copy",
      fun () ->
        (* In OCaml every formula value is the (single) node itself, so
           registering on [z] registers on the formula [x +~ 1] — the
           C++ observer-forwarding this test exercises cannot not
           happen. The observable contract is the same. *)
        let x = term 1 in
        let z = I.(Term x +~ Const 1) in
        let calls = ref 0 in
        on_change z (fun _ _ -> incr calls);
        set x 5;
        check_int "calls == 1" !calls 1 );
    ( "on_change / multiple listeners on the same formula",
      fun () ->
        let x = term 0 in
        let z = I.(Term x +~ Const 10) in
        let calls = ref 0 and sum = ref 0 in
        on_change z (fun _ _ -> incr calls);
        on_change z (fun _ n -> sum := !sum + n);
        set x 1;
        check_int "calls == 1" !calls 1;
        check_int "sum == 11" !sum 11 );
    ( "on_change / operator applied to auto-bound formula stays reactive",
      fun () ->
        let x = term 2 in
        let z = I.(Term x +~ Const 1) in
        let w = I.(z *~ Const 3) in
        check_int "w == 9" (eval w) 9;
        set x 3;
        check_int "w == 12" (eval w) 12 );
    ( "on_change / listener on formula built from auto-bound formula",
      fun () ->
        let x = term 2 in
        let z = I.(Term x +~ Const 1) in
        let w = I.(z *~ Const 3) in
        let calls = ref 0 in
        on_change w (fun _ _ -> incr calls);
        set x 3;
        check_int "w == 12" (eval w) 12;
        check_int "calls == 1" !calls 1 );
    ( "custom operator / test creation of custom unary op",
      fun () ->
        let x = term 3 in
        let z = map my_func (Term x) in
        check_int "z == 10" (eval z) 10;
        set x 4;
        check_int "z == 13" (eval z) 13 ) ]

let () =
  List.iter
    (fun (name, body) ->
      (try body ()
       with e ->
         incr failed;
         Printf.eprintf "FAILED: %s (exception %s)\n%!" name
           (Printexc.to_string e)))
    tests;
  Printf.printf "%d passed, %d failed\n%!" !passed !failed;
  if !failed > 0 then exit 1
