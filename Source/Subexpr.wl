(* ::Package:: *)

(* FormalCalc Subexpr (§0.1): address and operate on subexpressions the way you
   SEE them, not by tree position. A "locator" names where:
     - structural: integrand, summand, argOf[h] (e.g. argOf[Exp] = the exponent
       of e^x, argOf[Sqrt] = the radicand, argOf[Log] = inside the log),
       numerator, denominator
     - positional: term[n], factor[n], firstTerm, lastTerm
     - a pattern (anything with _), matching all such subexpressions
     - a concrete subexpression, matching it exactly
   on[where, op] applies op there (verified); partOf shows the piece; highlight
   boxes it in the displayed expression. Loaded in FormalCalc`Private`. *)

(* ---- locate: where -> list of part-positions ---- *)
joinPos[ps_, k_]            := (Append[#, k] &) /@ ps;
locate[e_, integrand]       := joinPos[Position[e, Inactive[Integrate][__], Heads -> False], 1];
locate[e_, summand]         := joinPos[Position[e, Inactive[Sum][__], Heads -> False], 1];
locate[e_, argOf[Exp]]      := joinPos[Position[e, Power[E, _], Heads -> False], 2];
locate[e_, argOf[Sqrt]]     := joinPos[Position[e, Power[_, 1/2], Heads -> False], 1];
locate[e_, argOf[h_]]       := joinPos[Position[e, h[_], Heads -> False], 1];
locate[e_, term[n_Integer]] := If[Head[e] === Plus && 1 <= n <= Length[e], {{n}}, {}];
locate[e_, firstTerm]       := locate[e, term[1]];
locate[e_, lastTerm]        := If[Head[e] === Plus, {{Length[e]}}, {}];
locate[e_, factor[n_Integer]] := If[Head[e] === Times && 1 <= n <= Length[e], {{n}}, {}];
locate[e_, where_]          := Position[e, where, Heads -> False];   (* pattern or concrete *)

locName[integrand]   = "integrand";  locName[summand] = "summand";
locName[numerator]   = "numerator";  locName[denominator] = "denominator";
locName[firstTerm]   = "first term"; locName[lastTerm] = "last term";
locName[argOf[h_]]   := "the argument of " <> ToString[h];
locName[term[n_]]    := "term " <> ToString[n];
locName[factor[n_]]  := "factor " <> ToString[n];
locName[w_]          := ToString[w, InputForm];

(* run a transform (plain or context-aware) on a subexpression *)
runOp[op_, e_, ctx_] := If[Head[op] === WithContext, First[op][e, ctx], op[e]];

onNote[opNote_, where_] := If[opNote =!= "", opNote <> " (in " <> locName[where] <> ")",
                              "in " <> locName[where]];

(* ============================================================ *)
(* on[where, op] : apply op at the located subexpression(s)     *)
(* ============================================================ *)
on::nopart = "No subexpression matched the locator `1`.";

(* numerator / denominator are semantic (rebuild, don't index) *)
on[numerator, op_] := WithContext[Function[{cur, ctx},
  With[{r = normalizeYield[runOp[op, Numerator[cur], ctx]]},
    Yields[r[[1]]/Denominator[cur], r[[2]], onNote[r[[3]], numerator], r[[4]]]]]];
on[denominator, op_] := WithContext[Function[{cur, ctx},
  With[{r = normalizeYield[runOp[op, Denominator[cur], ctx]]},
    Yields[Numerator[cur]/r[[1]], r[[2]], onNote[r[[3]], denominator], r[[4]]]]]];

on[where_, op_] := WithContext[Function[{cur, ctx}, Module[
  {pos = locate[cur, where], res, rels, rel, conds, assumed},
  If[pos === {}, Message[on::nopart, where]; cur,
    res = (normalizeYield[runOp[op, Extract[cur, #], ctx]] &) /@ pos;
    rels = res[[All, 2]];
    rel = If[AllTrue[rels, # === Equal &], Equal, First[DeleteCases[rels, Equal]]];
    conds = normalizeAsm[And @@ (Lookup[res[[All, 4]], "conditions", True])];
    assumed = AnyTrue[res[[All, 4]], TrueQ@Lookup[#, "assumed", False] &];
    Yields[ReplacePart[cur, Thread[pos -> res[[All, 1]]]], rel,
      onNote[res[[1, 3]], where], <|"conditions" -> conds, "assumed" -> assumed|>]]]]];

(* ============================================================ *)
(* inspect: what am I addressing?                               *)
(* ============================================================ *)
partOf[e_, numerator]   := Numerator[e];
partOf[e_, denominator] := Denominator[e];
partOf[e_, where_]      := With[{p = locate[e, where]},
  Which[p === {}, Missing["NoPart", where], Length[p] == 1, Extract[e, First[p]],
        True, Extract[e, #] & /@ p]];

highlight[e_, where_] := With[{p = locate[e, where]},
  If[p === {}, e,
    ReplacePart[e, (# -> Framed[Extract[e, #], Background -> LightYellow,
                                FrameStyle -> Orange, RoundingRadius -> 3]) & /@ p]]];
