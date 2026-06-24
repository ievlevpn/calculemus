(* ::Package:: *)

(* Calculemus Bounds (Layer 1, §9): sign/positivity certificates and
   single-quantity bounding transforms. Loaded inside Calculemus`Private`. *)

(* ============================================================ *)
(* Sign / positivity certificate (§9.7)                         *)
(* ============================================================ *)

(* cheap structural recognizers, then Simplify fallback *)
structurallyNonneg[0]                    := True;
structurallyNonneg[_?(NumericQ[#] && # >= 0 &)] := True;
structurallyNonneg[Power[_, n_Integer?EvenQ]] := True;
structurallyNonneg[_Abs]                 := True;
structurallyNonneg[a_Plus]               := AllTrue[List @@ a, structurallyNonneg];
structurallyNonneg[a_Times]              := AllTrue[List @@ a, structurallyNonneg];
structurallyNonneg[_]                    := False;

signOf[e_]            := signOf[e, True];
signOf[e_, asm_]      := Which[
  structurallyNonneg[e],            NonNegative,
  TrueQ[Simplify[e > 0, asm]],      Positive,
  TrueQ[Simplify[e < 0, asm]],      Negative,
  TrueQ[Simplify[e >= 0, asm]],     NonNegative,
  TrueQ[Simplify[e <= 0, asm]],     NonPositive,
  True,                             Unknown
];

(* ============================================================ *)
(* Bounding transforms (single-quantity chain)                  *)
(* ============================================================ *)

(* §9.4 — drop a nonnegative term: current >= current - term.
   Plus auto-cancels term if it is a literal summand of current. *)
dropTerm[term_] := Function[cur, Yields[cur - term, GreaterEqual, "drop nonneg term"]];

(* §9.3/9.6 — replace the whole expression by a claimed bound. *)
boundBy[newExpr_]            := boundBy[newExpr, LessEqual];
boundBy[newExpr_, rel_]      := Function[cur, Yields[newExpr, rel, "bound by given expr"]];

(* §9.3 — bound a subterm via a rule, asserting rel for the whole expression. *)
boundSub[rule_]             := boundSub[rule, LessEqual];
boundSub[rule_, rel_]       := Function[cur, Yields[cur /. rule, rel, "bound subterm"]];
