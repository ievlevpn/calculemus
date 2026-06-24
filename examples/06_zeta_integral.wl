(* ::Package:: *)

(* ============================================================================
   Example 6 - A genuinely hard integral, in three guided steps.

       Int_0^infinity  x^3 / (e^x - 1)  dx   =   pi^4 / 15.

   (The Bose-Einstein integral; it is the x^3 case behind the Stefan-Boltzmann
   law.) The standard trick: expand 1/(e^x - 1) as a geometric series, swap the
   sum and the integral, integrate each term (a Gamma integral), and recognize
   the resulting zeta(4) series.

   You supply the ONE insight - the geometric series. The CAS does the swap, the
   term-by-term integration, the summation, and verifies every step (here it can
   evaluate the pieces, so the checks are symbolic, not just numeric).
   ============================================================================ *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "FormalCalc.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "util.wl"}]];

d = derive[Inactive[Integrate][x^3/(E^x - 1), {x, 0, Infinity}], Assumptions -> x > 0];
d = step[d, rewrite[1/(E^x - 1) -> Inactive[Sum][E^(-k x), {k, 1, Infinity}]],
     "geometric series:  1/(e^x - 1) = Sum_{k>=1} e^{-k x}"];
d = step[d, swapSumIntegral,
     "swap the sum and the integral"];
d = step[d, Activate,
     "integrate each term (Int x^3 e^{-k x} = 6/k^4) and sum (6 zeta(4))"];

showChain["Int_0^inf x^3/(e^x - 1) dx", d];
Print["Result:  ", result[d], "  =  ", N[result[d]]];
Print["Three guided steps turned a hard improper integral into a closed form,"];
Print["each step verified by the CAS."];
