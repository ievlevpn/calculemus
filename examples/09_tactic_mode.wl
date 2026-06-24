(* ::Package:: *)

(* ============================================================================
   Example 9 - The paper-like "tactic" workflow.

   This is how the toolkit is meant to feel for incremental, page-after-page
   work: you start a computation, then add one verified line at a time with
   by[...] - reading just like the margin annotations in a hand derivation -
   and step back with undo[] if a move wasn't what you wanted. No reassignment,
   no result typed by hand (the CAS computes and checks each line).
   ============================================================================ *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "FormalCalc.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "util.wl"}]];

(* --- A hard integral, paper style ------------------------------------------ *)
compute[dint[x^3/(E^x - 1), {x, 0, Infinity}], Assumptions -> x > 0];
by[rewrite[1/(E^x - 1) -> sum[E^(-k x), {k, 1, Infinity}]], "geometric series"];
by[fubini,    "Fubini"];
by[evaluate,  "integrate each term, sum 6 zeta(4)"];
showChain["Int_0^inf x^3/(e^x-1) dx   (tactic mode)", goal[]];

(* --- A bound, with a wrong move undone -------------------------------------- *)
compute[Sqrt[u v] + w, Assumptions -> w >= 0];
by[amgm[u, v]];                 (* Sqrt[u v] <= (u+v)/2 ; accumulates u,v >= 0 *)
by[drop[w], "oops - meant to keep w"];
goal[];
undo[];                         (* take that move back *)
by[atMost[(u + v)/2 + w + 1], "loosen by 1"];
showChain["A bound, built and corrected with undo[]", goal[]];

(* --- Apply a monotone function to both sides of a relation ------------------ *)
compute[Log[P] <= B];
by[applyBoth[Exp], "exponentiate both sides"];
showChain["ln P <= B  =>  P <= e^B", goal[]];

Print["Each line was produced and verified by the CAS; you only named the moves."];
