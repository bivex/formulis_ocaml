(** Reactive programming with formulae.

    formulis is a radically simple reactive programming library. A
    {!term} stores a value that can change over time. A {!formula}
    combines terms (and other formulae) with operations and always
    evaluates to the most up-to-date value of each term it uses:

{[
  let x = Formulis.term 3 and y = Formulis.term 5 in
  let z = Formulis.Int.(Term x +~ Term y) in
  Formulis.eval z;                  (* 8 *)
  Formulis.set x 4;
  Formulis.eval z                   (* 9, updated automatically *)
]}

    Changes can also be observed with {!on_change}. This library is a
    faithful port of the original C++ header-only formulis; see the
    [docs/pages] directory for an overview of the internals. *)

(** {1 Fundamental types} *)

type 'a term
(** A mutable cell holding a value of type ['a]. When the value changes,
    every formula that uses the term is updated automatically. *)

type 'a formula
(** A reactive expression built from terms and/or other formulae. A
    formula caches its value and lazily recomputes it when a term it
    uses changes. Produced by {!map}, {!map2} and the operators of the
    {!Int}, {!Float} and {!Bool} modules. *)

type 'a expr = Const of 'a | Term of 'a term | Formula of 'a formula
(** An operand usable inside a formula: a plain constant, a term, or
    another formula. All operators take and return [expr]s, so chains
    like [Term x +~ Const 1 +~ Const 2] type-check without re-lifting. *)

(** {1 Terms} *)

val term : 'a -> 'a term
(** [term v] is a new term holding [v].

    "Copying" a term copies only its value: [term (get x)] produces an
    independent term with the same value, sharing no formulae nor
    listeners with [x] — just like C++ copy construction. *)

val get : 'a term -> 'a
(** The current value of a term. (For formulae use {!eval}.) *)

val set : 'a term -> 'a -> unit
(** [set t v] stores [v] into [t]. If the value changed (compared by
    structural equality, the analogue of C++ [operator==]), the term's
    {!on_change} listeners run first, then every formula that uses the
    term is marked dirty and recomputed. *)

val set_from : 'a term -> 'a expr -> unit
(** [set_from t e] stores the {i current} value of [e] into [t]. This is
    the analogue of the C++ [term::set(formula)]/[term::set(term)]
    overloads: only the current value is taken; [t] does {b not} become
    reactive on [e]. *)

(** {1 Formulae} *)

val eval : 'a expr -> 'a
(** The current value of an expression: constants contribute themselves,
    terms their value, and formulae their cached value — recomputing it
    if a term they use has changed. Pure: never writes the cache. *)

val on_change : 'a expr -> ('a -> 'a -> unit) -> unit
(** [on_change e f] runs [f old new] whenever the value of [e] changes.
    Listeners run in registration order, and receive the old and the new
    value.

    @raise Invalid_argument if [e] is a {!Const}, since constants never
    change. *)

val map : ('a -> 'b) -> 'a expr -> 'b expr
(** [map f e] is a formula whose value is [f] applied to the value of
    [e]. The analogue of the C++ [REGISTER_UNARY_PROC] macro: any unary
    function becomes a reactive operator. *)

val map2 : ('a -> 'b -> 'c) -> 'a expr -> 'b expr -> 'c expr
(** [map2 f a b] is a formula whose value is [f] applied to the values
    of [a] and [b]. This is what all binary operators are built from. *)

(** {1 Operator modules}

    OCaml has no overloading of [+] across types, so each C++ operator
    overload family becomes a small module: open (or alias) the one
    matching your operand type. The [~] suffix keeps the reactive
    operators apart from the plain OCaml ones. *)

module Int : sig
  val ( +~ ) : int expr -> int expr -> int expr
  (** Sum. (C++ [+]) *)

  val ( -~ ) : int expr -> int expr -> int expr
  (** Difference. (C++ [-]) *)

  val ( *~ ) : int expr -> int expr -> int expr
  (** Product. (C++ [*]) *)

  val ( /~ ) : int expr -> int expr -> int expr
  (** Integer division, truncating like C++ [/]. *)

  val ( %~ ) : int expr -> int expr -> int expr
  (** Remainder. (C++ [%]) *)

  val ( ^~ ) : int expr -> int expr -> int expr
  (** Bitwise exclusive or. (C++ [^]) *)

  val bit_and : int expr -> int expr -> int expr
  (** Bitwise and. (C++ [&]) *)

  val bit_or : int expr -> int expr -> int expr
  (** Bitwise or. (C++ [|]) *)

  val neg : int expr -> int expr
  (** Unary negation, reactive. (C++ unary [-]) *)

  val bit_not : int expr -> int expr
  (** Bitwise complement. (C++ [~]) *)

  val incr : int term -> unit
  (** [incr t] sets [t] to its value plus one. *)

  val decr : int term -> unit
  (** [decr t] sets [t] to its value minus one. *)

  val ( += ) : int term -> int -> unit
  (** [t += v] sets [t] to its value plus [v]. *)

  val ( -= ) : int term -> int -> unit
  (** [t -= v] sets [t] to its value minus [v]. *)

  val ( *= ) : int term -> int -> unit
  (** [t *= v] sets [t] to its value times [v]. *)

  val ( /= ) : int term -> int -> unit
  (** [t /= v] sets [t] to its value divided by [v]. *)

  val ( +=~ ) : int term -> int expr -> unit
  (** [t +=~ e] sets [t] to its value plus the current value of [e]. *)

  val ( -=~ ) : int term -> int expr -> unit
  (** [t -=~ e] sets [t] to its value minus the current value of [e]. *)

  val ( *=~ ) : int term -> int expr -> unit
  (** [t *=~ e] sets [t] to its value times the current value of [e]. *)

  val ( /=~ ) : int term -> int expr -> unit
  (** [t /=~ e] sets [t] to its value divided by the current value of
      [e]. *)
end

module Float : sig
  val ( +~ ) : float expr -> float expr -> float expr
  (** Sum. (C++ [+]) *)

  val ( -~ ) : float expr -> float expr -> float expr
  (** Difference. (C++ [-]) *)

  val ( *~ ) : float expr -> float expr -> float expr
  (** Product. (C++ [*]) *)

  val ( /~ ) : float expr -> float expr -> float expr
  (** Division. (C++ [/]) *)

  val ( **~ ) : float expr -> float expr -> float expr
  (** Exponentiation. *)

  val neg : float expr -> float expr
  (** Unary negation, reactive. (C++ unary [-]) *)
end

module Bool : sig
  val ( &&~ ) : bool expr -> bool expr -> bool expr
  (** Conjunction, without short-circuiting: both operands are always
      evaluated, like the C++ reactive [&&] overloads. The result is a
      [bool] formula. *)

  val ( ||~ ) : bool expr -> bool expr -> bool expr
  (** Disjunction, without short-circuiting. The result is a [bool]
      formula. *)

  val not : bool expr -> bool expr
  (** Negation, reactive. (C++ [!]) *)
end
