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

(* verification (incl. symbolic dimension n, infinite sums, and mixed sum+integral)
   is the unified inactiveCertify from the Integral module. *)
sumCertify[before_, after_, rel_, asm_] := inactiveCertify[before, after, rel, asm];
