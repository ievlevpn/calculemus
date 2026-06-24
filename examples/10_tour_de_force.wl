(* ::Package:: *)

(* ============================================================================
   Example 10 - TOUR DE FORCE.

   One extended derivation, paper style, in tactic mode, assembling the pieces of
   a high-exceedance asymptotic for a vector-valued Gaussian field (the setting of
   arXiv:2401.05527). It runs through, with EVERY line verified:

     Phase 1  non-commutative algebra : expand the perturbed inverse covariance
              (Neumann series, V small), abbreviate G := Sigma^{-1}.
     Phase 2  operator relation       : a first-order term w^T(A+A^T)w vanishes
              because of the optimality relation A w = 0.
     Phase 3  Gaussian integral        : complete the square INSIDE the exponent
              (subexpression addressing) and evaluate the Gaussian.
     Phase 4  sums over n components    : bound each term by an inequality
              (log(1+x) <= x) and pull the constant out - n a SYMBOL, not a number.
     Phase 5  two-sided relation        : exponentiate a log-bound to bound Q.
   ============================================================================ *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "FormalCalc.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "util.wl"}]];

ncDeclareSym[CapSigma];           (* covariance: symmetric positive-definite *)
ncDeclare[V, A];                  (* perturbation V(t); optimality matrix A   *)
ncDeclareVec[w];                  (* the most-likely-exceedance direction      *)

(* ---- Phase 1 : the perturbed inverse covariance Sigma(t)^{-1} = (Sigma - V)^{-1} ---- *)
compute[inv[CapSigma - V], Grading -> {V -> 1}, GradingOrder -> 2];
by[expandInverse[CapSigma, V, 2], "Neumann expansion, V small"];
by[let[G, inv[CapSigma]],          "abbreviate G := Sigma^{-1}"];
showChain["Phase 1 - perturbed inverse  (Sigma - V)^{-1}", goal[]];

(* ---- Phase 2 : the first-order term drops out by optimality (A w = 0) ---- *)
compute[tp[w] ** (A + tp[A]) ** w, Relations -> {A ** w -> 0, tp[w] ** tp[A] -> 0}];
by[NCExpand,    "expand the symmetric quadratic form"];
by[applyRel[],  "apply the optimality relation A w = 0"];
showChain["Phase 2 - first-order term  w^T(A + A^T)w = 0", goal[]];

(* ---- Phase 3 : the leading Gaussian integral over the local field ---- *)
compute[dint[Exp[-(a/2) x^2 + b x], {x, -Infinity, Infinity}], Assumptions -> a > 0];
by[on[argOf[Exp], completeSquare[x]], "complete the square in the exponent"];
by[gaussianIntegral,                  "evaluate the Gaussian integral"];
showChain["Phase 3 - leading Gaussian integral", goal[]];

(* ---- Phase 4 : sum the corrections over the n components (n symbolic) ---- *)
compute[sum[Log[1 + e/i^2], {i, 1, n}], Assumptions -> e > 0];
by[on[summand, logBound[e/i^2]], "log(1 + x) <= x  on each term"];
by[sumLinearity,                 "pull the constant e out of the sum"];
showChain["Phase 4 - bound the sum over n components (n a symbol)", goal[]];

(* ---- Phase 5 : turn the log-bound into a bound on the probability Q ---- *)
compute[Log[Q] <= B];
by[applyBoth[Exp], "exponentiate both sides (exp is increasing)"];
showChain["Phase 5 - log-bound  =>  bound on Q", goal[]];

Print["Five phases, every line produced and verified by the CAS - the kind of"];
Print["multi-page derivation where one unnoticed slip on page 3 would ruin the rest."];
