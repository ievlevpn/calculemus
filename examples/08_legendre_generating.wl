(* ::Package:: *)

(* ============================================================================
   Example 8 - Reading a family of special polynomials off a generating function.

   The generating function of the Legendre polynomials is

       1 / sqrt(1 - 2 x t + t^2)  =  sum_{n>=0} P_n(x) t^n.

   Expanding the left-hand side to a given order in t and collecting powers of t
   produces P_0, P_1, P_2, ... You name one move - "expand to order 3 in t"; the
   CAS does the (messy) graded expansion of a nested square root, verified by the
   graded ~ check, and the coefficients turn out to be exactly the LegendreP_n.
   ============================================================================ *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "Calculemus.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "util.wl"}]];

(* t is the small generator (weight 1); expand to 3rd order. *)
d = derive[1/Sqrt[1 - 2 x t + t^2], Grading -> {t -> 1}, GradingOrder -> 3];
d = step[d, dropHigherOrder[], "expand the generating function to O(t^3)"];
showChain["Legendre generating function  1/sqrt(1 - 2 x t + t^2)", d];

(* The coefficients of t^n are the Legendre polynomials - check against built-ins. *)
coeffs = CoefficientList[result[d], t];
Print["coefficient of t^n            :  ", Expand[coeffs]];
Print["LegendreP[n, x] for n=0..3     :  ", Expand[Table[LegendreP[n, x], {n, 0, 3}]]];
Print["match: ", Expand[coeffs] === Expand[Table[LegendreP[n, x], {n, 0, 3}]]];
