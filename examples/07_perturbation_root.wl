(* ::Package:: *)

(* ============================================================================
   Example 7 - Regular perturbation theory: the asymptotic root of an equation
   with no closed-form solution.

       Solve   x = 1 + eps x^3   for x(eps),  with x(0) = 1,  as a series in eps.

   You write the equation and the ansatz x = 1 + a1 eps + a2 eps^2 + ... The CAS
   substitutes, expands in eps, peels off the equation at each order, and solves
   them in sequence. The toolkit then VERIFIES the result: plugging the series
   back in, the residual vanishes through the claimed order (a graded ~ check).
   ============================================================================ *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "Calculemus.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "util.wl"}]];

eqn    = x - 1 - eps x^3;                 (* solve eqn == 0,  x(0) = 1 *)
ansatz = 1 + a1 eps + a2 eps^2;           (* you propose the form *)
order  = 2;

(* The CAS expands the substituted equation to O(eps^2) ... *)
expanded = seriesExpand[eqn /. x -> ansatz, {eps -> 1}, order];
(* ... peels off the coefficient of each power of eps (these must vanish) ... *)
orderEqns = Rest[CoefficientList[expanded, eps]];   (* drop the O(1) term (=0) *)
(* ... and solves them order by order. *)
sol  = First@Solve[Thread[orderEqns == 0], {a1, a2}];
xsol = ansatz /. sol;

Print["Solved coefficients:  ", sol];
Print["Perturbative root:    x(eps) = ", xsol, " + O(eps^3)"];
Print[""];

(* Verification: substitute the series back; the residual must be O(eps^3). *)
d = derive[eqn /. x -> xsol, Grading -> {eps -> 1}, GradingOrder -> order];
d = step[d, dropHigherOrder[], "residual of the equation, through O(eps^2)"];
showChain["Residual  x(eps) - 1 - eps x(eps)^3  to O(eps^2)", d];

Print["The residual is certified to vanish to the claimed order, so the series"];
Print["solves the equation through O(eps^2). (True root: x = 1 + eps + 3 eps^2 + ...)"];
