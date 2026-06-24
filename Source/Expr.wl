(* ::Package:: *)

(* FormalCalc Expr (Layer 1, §1-§2): general-purpose expression algebra.
   Nothing domain-specific lives here. Loaded in FormalCalc`Private`. *)

(* §2 complete the square (scalar):  a x^2 + b x + c  ->  a (x + b/2a)^2 + (c - b^2/4a). *)
completeSquare[x_] := Function[cur,
  With[{aa = Coefficient[cur, x, 2], bb = Coefficient[cur, x, 1], cc = Coefficient[cur, x, 0]},
    aa (x + bb/(2 aa))^2 + (cc - bb^2/(4 aa))]];
