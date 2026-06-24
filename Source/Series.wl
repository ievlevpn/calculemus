(* ::Package:: *)

(* FormalCalc Series (Layer 1, §4.3-4.5): graded weighted truncation,
   series expansion to weighted order, and o/O bookkeeping markers.
   Loaded inside FormalCalc`Private`.

   A *grading* assigns each "small" generator a positive weight. The weight
   of a monomial Prod g_i^p_i is Sum p_i*w_i. Truncation keeps monomials of
   weight <= order; expansion generates a series then truncates. This is the
   mechanism behind the asymptotic expansions in arXiv:2401.05527 (e.g. the
   Neumann expansion of Sigma^{-1}(t), Lemma "Sigma-inverse"). *)

(* ---- grading specification ---- *)
(* Accept {g -> w, ...}, {g, ...} (weight 1), a bare rule, or a bare symbol. *)
normalizeGrading[g_List] := Replace[g, {(r_Rule) :> r, x_ :> (x -> 1)}, {1}];
normalizeGrading[r_Rule]  := {r};
normalizeGrading[x_]      := {x -> 1};

(* weight of a single monomial under a grading *)
monomialWeight[term_, grading_] := With[{ng = normalizeGrading[grading]},
  Total[(Exponent[term, First[#]] Last[#]) & /@ ng]
];

(* ---- decide weight <= order (numeric fast path, else Simplify) ---- *)
truncate::undecided = "Could not decide weight `1` <= `2` under the assumptions; keeping the term (conservative).";
weightLeqQ[w_, order_, asm_] := Module[{v},
  If[NumericQ[w] && NumericQ[order], Return[w <= order]];
  v = Simplify[w <= order, asm];
  Which[v === True, True, v === False, False,
        True, Message[truncate::undecided, w, order]; True]
];

(* ---- §4.3 truncate an (already polynomial) expression by weighted degree ---- *)
truncate[expr_, grading_, order_] := truncate[expr, grading, order, True];
truncate[expr_, grading_, order_, asm_] := Module[{ng = normalizeGrading[grading], ex, terms},
  ex = Expand[expr];
  terms = If[Head[ex] === Plus, List @@ ex, {ex}];
  Total@Select[terms, weightLeqQ[monomialWeight[#, ng], order, asm] &]
];

(* ---- §4.5 series expansion to weighted order ----
   Rational weights + numeric order: homogenize each generator g -> eps^w g,
   take the native series in eps to the given order, then set eps -> 1. This
   reuses Mathematica's series machinery (handles reciprocals, exp, log, ...).
   Symbolic weights/order: fall back to polynomial truncation. *)
seriesExpand[expr_, grading_, order_] := seriesExpand[expr, grading, order, True];
seriesExpand[expr_, grading_, order_, asm_] := Module[
  {ng = normalizeGrading[grading], eps, subs},
  If[! (AllTrue[Last /@ ng, NumericQ] && NumericQ[order]),
    Return[truncate[Expand[expr], ng, order, asm]]];
  subs = (First[#] -> eps^Last[#] First[#]) & /@ ng;
  Expand[Normal[Series[expr /. subs, {eps, 0, order}]] /. eps -> 1]
];

(* ---- transform: expand & drop higher-order terms, asserting a ~ step ----
   Verified automatically when the derivation carries a matching grading. *)
dropHigherOrder[grading_, order_] :=
  Function[cur, Yields[seriesExpand[cur, grading, order], AsymEqual, "expand & drop higher-order"]];

(* context-aware: read Grading / GradingOrder from the derivation (set once) *)
dropHigherOrder[] := WithContext[Function[{expr, ctx},
  Yields[seriesExpand[expr, ctx["grading"], ctx["order"]], AsymEqual, "expand & drop higher-order"]]];

(* ============================================================ *)
(* §4.4 minimal o / O bookkeeping markers                       *)
(* ============================================================ *)
littleO /: littleO[s_] + littleO[s_]      := littleO[s];
littleO /: c_?NumericQ littleO[s_]        := littleO[s] /; c =!= 0;
bigO    /: bigO[s_] + bigO[s_]            := bigO[s];
bigO    /: c_?NumericQ bigO[s_]           := bigO[s] /; c =!= 0;
bigO    /: littleO[s_] + bigO[s_]         := bigO[s];
