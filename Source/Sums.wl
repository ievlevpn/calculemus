(* ::Package:: *)

(* FormalCalc Sums (Layer 1, §5): formal manipulation of sums held as
   Inactive[Sum]. Pure rewrites, never evaluated. Verification: finite sums
   Activate to explicit term sums, so Simplify proves the equality; a numeric
   probe (random params) backs it up. Loaded in FormalCalc`Private`. *)

sum[f_, {k_, a_, b_}] := Inactive[Sum][f, {k, a, b}];

(* §5.4 linearity: split over sums, pull factors free of the index *)
sumLinearity := Function[cur, cur //. {
  Inactive[Sum][s_Plus, dom_] :> (Inactive[Sum][#, dom] & /@ s),
  Inactive[Sum][p_Times, {k_, a_, b_}] /; (Select[p, FreeQ[#, k] &] =!= 1) :>
    With[{free = Select[p, FreeQ[#, k] &], dep = Select[p, ! FreeQ[#, k] &]},
      free Inactive[Sum][dep, {k, a, b}]]
}];

(* §5.1 shift the summation index by c (reindex, summand adjusted) *)
shiftIndex[c_] := Function[cur,
  cur /. Inactive[Sum][f_, {k_, a_, b_}] :>
    Inactive[Sum][f /. k -> k - c, {k, a + c, b + c}]];

(* §5.2 split the range at an interior point m *)
splitSum[m_] := Function[cur,
  cur /. Inactive[Sum][f_, {k_, a_, b_}] :>
    Inactive[Sum][f, {k, a, m}] + Inactive[Sum][f, {k, m + 1, b}]];

(* §5.2 peel off the first / last term:  Sum_{k=a}^b f = f(a) + Sum_{k=a+1}^b f. *)
peelFirst := Function[cur,
  cur /. Inactive[Sum][f_, {k_, a_, b_}] :> (f /. k -> a) + Inactive[Sum][f, {k, a + 1, b}]];
peelLast := Function[cur,
  cur /. Inactive[Sum][f_, {k_, a_, b_}] :> Inactive[Sum][f, {k, a, b - 1}] + (f /. k -> b)];

(* §5.3 interchange the order of two nested sums (Fubini), bounds independent *)
swapSum := Function[cur,
  cur /. Inactive[Sum][Inactive[Sum][f_, {j_, c_, d_}], {k_, a_, b_}] :>
    Inactive[Sum][Inactive[Sum][f, {k, a, b}], {j, c, d}]];

(* ============================================================ *)
(* Verification                                                 *)
(* ============================================================ *)
sumExprQ[e_] := ! FreeQ[e, Inactive[Sum]];

sumIndexVars[e_] := DeleteDuplicates@Cases[e, Inactive[Sum][_, {v_, _, _}] :> v, {0, Infinity}];
sumParams[e_] := Complement[
  DeleteDuplicates@Cases[e, s_Symbol /; (Context[s] =!= "System`" && ! NumericQ[s]), {0, Infinity}],
  sumIndexVars[e]];

(* symbolic: Activate the (finite) sums and prove the difference is 0 *)
sumSymZero[before_, after_, asm_] := TrueQ@Quiet@TimeConstrained[
  Simplify[Activate[before] - Activate[after], asm] === 0, 5, False];

(* symbols appearing in summation BOUNDS (e.g. the n in Sum_{i=1}^n) - these must
   be tested at concrete INTEGER dimensions, not real values. *)
sumBoundSyms[e_] := DeleteDuplicates@Cases[
  Cases[e, Inactive[Sum][_, {_, lo_, hi_}] :> {lo, hi}, {0, Infinity}],
  s_Symbol /; Context[s] =!= "System`", {0, Infinity}];

(* numeric: test at several concrete dimensions (bound symbols -> small integers,
   so Sum_{i=1}^n becomes a finite sum) and random reals for the other params. *)
sumProbe[before_, after_, rel_, asm_, trials_: 8] := Module[{bsyms, vparams, res, tol = 10.^-6},
  bsyms = sumBoundSyms[{before, after}];
  vparams = Complement[Union[sumParams[before], sumParams[after]], bsyms];
  res = Table[
    Module[{sub, bn, an},
      sub = Join[(# -> RandomInteger[{2, 6}]) & /@ bsyms, (# -> RandomReal[{0.4, 2.2}]) & /@ vparams];
      Quiet@Check[
        bn = N[Activate[before] /. sub]; an = N[Activate[after] /. sub];
        numericRelHolds[rel, bn, an, tol], $bad]],
    {trials}];
  res = DeleteCases[res, $bad | Indeterminate];
  Which[res === {}, Unknown, MemberQ[res, False], False, True, True]
];

sumCertify[before_, after_, rel_, asm_] := Module[{sz, pr, status},
  sz = rel === Equal && sumSymZero[before, after, asm];
  pr = sumProbe[before, after, rel, asm];
  status = Which[pr === False, "Refuted", sz, "Verified", pr === True, "NumericOnly", True, "Unverified"];
  <|"relation" -> rel, "symbolic" -> If[sz, True, Unknown],
    "numeric" -> <|"verdict" -> pr|>, "status" -> status|>
];
