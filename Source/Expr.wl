(* ::Package:: *)

(* FormalCalc Expr (Layer 1, §1-§2): general-purpose expression algebra.
   Nothing domain-specific lives here. Loaded in FormalCalc`Private`. *)

(* §1.1 abbreviation: name a subexpression w := expr, work with w, restore later.
   The definition w -> expr is recorded on the derivation; verification expands it,
   so steps stay readable in w while the real math is what gets checked. *)
abbreviate[w_, expr_] := Function[cur,
  Yields[cur /. expr -> w, Equal,
    "let " <> ToString[w] <> " := " <> ToString[expr, InputForm], <|"define" -> (w -> expr)|>]];

(* restore[w]: replace w by its recorded definition.  restoreAll: expand every abbreviation. *)
restore[w_] := WithContext[Function[{cur, ctx},
  Yields[cur //. Cases[ctx["defs"], HoldPattern[w -> _]], Equal, "restore " <> ToString[w]]]];
restoreAll := WithContext[Function[{cur, ctx},
  Yields[cur //. ctx["defs"], Equal, "restore all abbreviations"]]];

(* §2 complete the square (scalar):  a x^2 + b x + c  ->  a (x + b/2a)^2 + (c - b^2/4a). *)
completeSquare[x_] := Function[cur,
  With[{aa = Coefficient[cur, x, 2], bb = Coefficient[cur, x, 1], cc = Coefficient[cur, x, 0]},
    aa (x + bb/(2 aa))^2 + (cc - bb^2/(4 aa))]];
