(* ::Package:: *)

(* ============================================================================
   Example 1 - Asymptotic expansion of a perturbed matrix inverse.

   In the analysis of extremes of vector-valued Gaussian fields you repeatedly
   need the inverse covariance  Sigma^{-1}(t)  for small t, where the covariance
   splits as   Sigma(t) = S - V,   with V = V(t) -> 0 a small perturbation.
   This is the (non-commutative) Neumann / geometric expansion of an inverse:

       (S - V)^{-1} = S^{-1} + S^{-1} V S^{-1} + S^{-1} V S^{-1} V S^{-1} + ...

   What you do by hand: nothing but "expand this inverse to 2nd order in V."
   What the CAS does: builds the operator series and CHECKS it on random
   symmetric-positive-definite S and random V (so the answer is not just formal).
   ============================================================================ *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "Calculemus.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "util.wl"}]];

ncDeclareSym[S];   (* covariance: symmetric positive-definite *)
ncDeclare[V];      (* small perturbation V(t), the weight-1 generator *)

(* You guide: start from the inverse, declare V small (weight 1), expand to O(V^2) *)
d = derive[inv[S - V], Grading -> {V -> 1}, GradingOrder -> 2];
d = step[d, expandInverse[S, V, 2],
     "Neumann-expand inv[S - V] to 2nd order in V"];

showChain["Perturbed inverse  (S - V)^{-1}  to second order", d];

Print["The single command produced the full operator series; the ~ step was"];
Print["verified by checking the residual is O(V^3) on random SPD S and random V."];
