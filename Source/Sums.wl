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

(* numeric: random reals for free params, Activate, compare *)
sumProbe[before_, after_, asm_, trials_: 6] := Module[{params, res, tol = 10.^-6},
  params = Union[sumParams[before], sumParams[after]];
  res = Table[
    Module[{sub = (# -> RandomReal[{0.4, 2.2}]) & /@ params, bn, an},
      Quiet@Check[
        bn = N[Activate[before] /. sub]; an = N[Activate[after] /. sub];
        If[NumericQ[bn] && NumericQ[an], Abs[an - bn] <= tol (1 + Abs[bn]), $bad],
        $bad]],
    {trials}];
  res = DeleteCases[res, $bad];
  Which[res === {}, Unknown, MemberQ[res, False], False, True, True]
];

sumCertify[before_, after_, Equal, asm_] := Module[{sz, pr, status},
  sz = sumSymZero[before, after, asm];
  pr = sumProbe[before, after, asm];
  status = Which[pr === False, "Refuted", sz, "Verified", pr === True, "NumericOnly", True, "Unverified"];
  <|"relation" -> Equal, "symbolic" -> If[sz, True, Unknown],
    "numeric" -> <|"verdict" -> pr|>, "status" -> status|>
];
sumCertify[before_, after_, rel_, asm_] :=
  <|"relation" -> rel, "symbolic" -> Unknown, "numeric" -> <|"verdict" -> Unknown|>,
    "status" -> "Unverified"|>;
