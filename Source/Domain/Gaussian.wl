(* ::Package:: *)

(* FormalCalc`Gaussian` - DOMAIN PACK (Gaussian / extreme-value probability).
   A SEPARATE context, deliberately NOT loaded by the general FormalCalc core.
   Everything overly specific to Gaussian-process work lives here: probabilistic
   objects (log-densities, density ratios) and, in future, the named process
   inequalities (Slepian, Borell-TIS, Piterbarg).

   Load it explicitly on top of the core:
       Get[".../Kernel/FormalCalc.wl"]            (* general toolkit *)
       Get[".../Source/Domain/Gaussian.wl"]       (* this pack         *)

   General math used here (complete-the-square, Gaussian integral, quadratic
   forms) is NOT redefined - it lives in the core (Expr / Matrix / Integral). *)

BeginPackage["FormalCalc`Gaussian`", {"FormalCalc`", "NonCommutativeMultiply`"}];

gaussExp::usage          = "gaussExp[x, s] = -1/2 tp[x] ** inv[s] ** x, the exponent of a centered Gaussian log-density (covariance s).";
prefactorExponent::usage = "prefactorExponent[x1, s1, x2, s2] = gaussExp[x1,s1] - gaussExp[x2,s2], the exponent of a Gaussian log-density ratio (the 'exponential prefactor').";

Begin["`Private`"];

gaussExp[x_, s_] := -1/2 tp[x] ** inv[s] ** x;
prefactorExponent[x1_, s1_, x2_, s2_] := gaussExp[x1, s1] - gaussExp[x2, s2];

End[];
EndPackage[];
