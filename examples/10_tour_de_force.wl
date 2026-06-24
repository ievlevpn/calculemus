(* ::Package:: *)

(* ============================================================================
   Example 10 - TOUR DE FORCE: ONE long computation.

       Int_0^infinity  x^{s-1} / (e^x - 1)  dx   =   Gamma(s) Zeta(s).

   The classical Mellin derivation of the Riemann zeta / Bose-Einstein integral:
   ONE quantity, carried through nine verified steps - geometric series, Fubini,
   a change of variables performed inside the summand, a power split, pulling a
   constant out, recognizing the Gamma integral, and the Zeta sum. Every line is
   produced and checked by the CAS (here it can evaluate the pieces, so the checks
   are symbolic / via Gamma and Zeta).
   ============================================================================ *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "Calculemus.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "util.wl"}]];

compute[dint[x^(s - 1)/(E^x - 1), {x, 0, Infinity}], Assumptions -> s > 1];

by[rewrite[1/(E^x - 1) -> sum[E^(-k x), {k, 1, Infinity}]],
   "geometric series:  1/(e^x - 1) = Sum_{k>=1} e^{-k x}"];

by[fubini,
   "Tonelli: interchange the sum and the integral"];

by[on[summand, changeVar[u, u/k, {0, Infinity}]],
   "in each term substitute x = u/k"];

by[on[summand, PowerExpand],
   "split (u/k)^{s-1} = u^{s-1} k^{1-s}"];

by[on[summand, linearity],
   "pull k^{-s} out of each integral"];

by[on[summand, rewrite[dint[u^(s - 1) E^(-u), {u, 0, Infinity}] -> Gamma[s]]],
   "recognize Gamma(s) = Int_0^inf u^{s-1} e^{-u} du"];

by[sumLinearity,
   "pull Gamma(s) out of the sum"];

by[rewrite[sum[k^(-s), {k, 1, Infinity}] -> Zeta[s]],
   "recognize Zeta(s) = Sum_{k>=1} k^{-s}"];

showChain["Int_0^inf x^{s-1}/(e^x - 1) dx", goal[]];
Print["Result:  ", result[goal[]]];
Print["Verified throughout: ", verifiedQ[goal[]]];
Print[""];
Print["One quantity, nine verified lines - a derivation that across paper pages"];
Print["would be easy to corrupt with a single unnoticed slip."];
