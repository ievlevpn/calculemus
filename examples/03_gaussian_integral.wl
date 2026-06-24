(* ::Package:: *)

(* ============================================================================
   Example 3 - A Gaussian integral by completing the square.

   The workhorse of Gaussian computations:
       Int_{-inf}^{inf} exp(-a/2 x^2 + b x) dx  =  sqrt(2 pi / a) exp(b^2/(2a)).

   Part A shows the algebraic move on its own (complete the square in the
   exponent); Part B normalizes the whole integral in one step. You only name
   the moves; the CAS does the algebra and the closed form, and checks Part B by
   numerical quadrature at random a, b.
   ============================================================================ *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "Calculemus.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "util.wl"}]];

(* Part A - complete the square in the exponent (you just say "complete it") *)
dA = derive[-(a/2) x^2 + b x, Assumptions -> a > 0];
dA = step[dA, completeSquare[x], "complete the square in x"];
showChain["Complete the square:  -a/2 x^2 + b x", dA];

(* Part B - normalize the full Gaussian integral *)
dB = derive[Inactive[Integrate][Exp[-(a/2) x^2 + b x], {x, -Infinity, Infinity}],
            Assumptions -> a > 0];
dB = step[dB, gaussianIntegral, "evaluate the Gaussian integral in closed form"];
showChain["Gaussian integral  Int exp(-a/2 x^2 + b x) dx", dB];

Print["You supplied two words ('complete', 'gaussian integral'); the CAS produced"];
Print["the completed exponent and the closed form, checked by quadrature."];
