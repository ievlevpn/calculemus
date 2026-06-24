(* ::Package:: *)

(* ============================================================================
   Example 4 - Integration by parts, with the CAS finding the antiderivatives.

   Reduce   Int_0^1 x^2 e^x dx   by parts twice. You only choose the factor u to
   differentiate; the CAS computes the antiderivative v of the rest, the
   boundary term, and the new (held) remainder integral. Every step is checked
   by numerical quadrature, so a wrong boundary term would be caught immediately.

   Also shown: a change of variables where the new limits are SOLVED for you.
   ============================================================================ *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "FormalCalc.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "util.wl"}]];

(* You guide: "by parts with u = x^2", then "by parts with u = 2x". *)
d = derive[dint[x^2 Exp[x], {x, 0, 1}]];
d = step[d, ibp[x^2], "by parts, u = x^2  (CAS finds v = e^x)"];
d = step[d, linearity, "pull the constant out of the remainder integral"];
d = step[d, ibp[2 x],  "by parts again, u = 2x  (CAS finds v = e^x)"];
showChain["Int_0^1 x^2 e^x dx  by parts (twice)", d];

(* Change of variables with auto-solved limits. Use a monotonic substitution so
   the new limits are unambiguous; for multivalued x = phi(u) pass {na, nb}. *)
d2 = derive[dint[Exp[2 x], {x, 0, 1}]];
d2 = step[d2, changeVar[u, u/2], "substitute x = u/2  (CAS solves the new limits 0..2)"];
showChain["Change of variables  x = u/2  in  Int_0^1 e^{2x} dx", d2];

Print["You picked only the parts/substitution; antiderivatives, boundary terms"];
Print["and new limits were computed and quadrature-checked for you."];
