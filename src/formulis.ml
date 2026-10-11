(* formulis: reactive programming with formulae.
   OCaml port of the original C++ header-only library of the same name. *)

(* A "dependent" is anything that must react when an observable node (a
   term or a formula) changes. It always wraps a formula: on
   notification the formula is marked dirty and then updated, exactly
   like C++ term::change_detected does for its parent formulae. *)
type dependent = { notify : unit -> unit }

type 'a term = {
  (* Current value (C++ m_value). *)
  mutable value : 'a;
  (* Formulae using this term, in creation order (C++ m_parents). *)
  mutable parents : dependent list;
  (* Functions run with (old, new) on change (C++ m_on_change). *)
  mutable listeners : ('a -> 'a -> unit) list;
}

type 'a formula = {
  (* True when [cached] may be out of date (C++ m_needs_update). *)
  mutable dirty : bool;
  (* Recomputes the value from the operands. The C++ library models this
     with unary_expr/bin_expr over a stmt variant; a closure is the
     direct OCaml translation of std::function. *)
  compute : unit -> 'a;
  (* Last computed value (C++ m_cached_val). *)
  mutable cached : 'a;
  mutable listeners : ('a -> 'a -> unit) list;
  mutable parents : dependent list;
}

type 'a expr = Const of 'a | Term of 'a term | Formula of 'a formula

(* --- Evaluation ------------------------------------------------------ *)

(* Current value of a formula: the cache when clean, a fresh (but
   uncached) computation when dirty — like C++ formula::eval. *)
let eval_formula f = if f.dirty then f.compute () else f.cached

(* C++ formula::update: recompute the cache; if the value changed, fire
   the listeners, clear the dirty flag and propagate to the parents. *)
let update_formula f =
  let old = f.cached in
  f.cached <- eval_formula f;
  if old <> f.cached then begin
    List.iter (fun listener -> listener old f.cached) f.listeners;
    f.dirty <- false;
    List.iter (fun parent -> parent.notify ()) f.parents
  end

(* The dependent handle a formula presents to its operands. *)
let dependent_of f = { notify = fun () -> f.dirty <- true; update_formula f }

(* Register a formula as a dependent of an operand. Constants never
   change (C++ const_), so there is nothing to link. *)
let link parent = function
  | Const _ -> ()
  | Term t -> t.parents <- t.parents @ [ parent ]
  | Formula f -> f.parents <- f.parents @ [ parent ]

(* Build a formula over its operands, wiring it in as their dependent.
   The value is computed once up front, mirroring the C++ constructor's
   m_cached_val(eval()). *)
let new_formula compute link_operands =
  let f =
    {
      dirty = true;
      compute;
      cached = compute ();
      listeners = [];
      parents = [];
    }
  in
  link_operands (dependent_of f);
  f

let eval = function
  | Const v -> v
  | Term t -> t.value
  | Formula f -> eval_formula f

(* --- Terms ------------------------------------------------------------ *)

let term v = { value = v; parents = []; listeners = [] }

let get t = t.value

(* C++ term::set + change_detected: store the value; if it changed, run
   the listeners first, then notify every dependent formula. *)
let set t v =
  let old = t.value in
  t.value <- v;
  if old <> v then begin
    List.iter (fun listener -> listener old v) t.listeners;
    List.iter (fun parent -> parent.notify ()) t.parents
  end

let set_from t e = set t (eval e)

let on_change e listener =
  match e with
  | Const _ -> invalid_arg "Formulis.on_change: constants never change"
  | Term t -> t.listeners <- t.listeners @ [ listener ]
  | Formula f -> f.listeners <- f.listeners @ [ listener ]

(* --- Combinators ------------------------------------------------------ *)

let map fn a = Formula (new_formula (fun () -> fn (eval a)) (fun dep -> link dep a))

let map2 fn a b =
  Formula (new_formula (fun () -> fn (eval a) (eval b)) (fun dep ->
      link dep a;
      link dep b))

(* --- Operator modules ------------------------------------------------- *)

module Int = struct
  let ( +~ ) a b = map2 ( + ) a b
  let ( -~ ) a b = map2 ( - ) a b
  let ( *~ ) a b = map2 ( * ) a b
  let ( /~ ) a b = map2 ( / ) a b
  let ( %~ ) a b = map2 (mod) a b
  let ( ^~ ) a b = map2 (lxor) a b
  let bit_and a b = map2 (land) a b
  let bit_or a b = map2 (lor) a b
  let neg a = map (~-) a
  let bit_not a = map lnot a

  let incr t = set t (get t + 1)
  let decr t = set t (get t - 1)

  let ( += ) t v = set t (get t + v)
  let ( -= ) t v = set t (get t - v)
  let ( *= ) t v = set t (get t * v)
  let ( /= ) t v = set t (get t / v)
  let ( +=~ ) t e = set t (get t + eval e)
  let ( -=~ ) t e = set t (get t - eval e)
  let ( *=~ ) t e = set t (get t * eval e)
  let ( /=~ ) t e = set t (get t / eval e)
end

module Float = struct
  let ( +~ ) a b = map2 ( +. ) a b
  let ( -~ ) a b = map2 ( -. ) a b
  let ( *~ ) a b = map2 ( *. ) a b
  let ( /~ ) a b = map2 ( /. ) a b
  let ( **~ ) a b = map2 ( ** ) a b
  let neg a = map (~-.) a
end

module Bool = struct
  let ( &&~ ) a b = map2 ( && ) a b
  let ( ||~ ) a b = map2 ( || ) a b
  let not a = map not a
end
