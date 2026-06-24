(* ::Package:: *)

(* FormalCalc non-commutative / matrix self-checks.
     wolframscript -file Tests/MatrixTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "FormalCalc.wl"}]];

ClearAll[assert];
SetAttributes[assert, HoldFirst];
assert[cond_, label_: ""] := If[TrueQ[cond], $passed++,
  Print["FAILED: ", label, " :: ", HoldForm[cond]]; Exit[1]];
$passed = 0;
ncSame[a_, b_] := NCExpand[a - b] === 0;

ncDeclare[s, e, x, y, z, mA, mB];

(* ---- NC equality verified (symbolic NCExpand) ---- *)
dEq = derive[x ** (y + z)] // step[NCExpand];
assert[ncSame[result[dEq], x ** y + x ** z], "dEq result"];
assert[relationOf[dEq] === Equal, "dEq relation"];
assert[verifiedQ[dEq], "dEq verified"];

(* ---- NC equality refuted by random-matrix probe (matrices don't commute) ---- *)
dBad = Quiet@step[derive[x ** y], (# /. x ** y -> y ** x &)];
assert[stepsOf[dBad][[1]]["cert"]["status"] === "Refuted", "dBad refuted"];

(* ---- NC equality that is genuinely non-commutative (cross terms don't cancel) ---- *)
dEq2 = derive[(mA + mB) ** (mA - mB)] // step[NCExpand];
assert[ncSame[result[dEq2], mA ** mA - mA ** mB + mB ** mA - mB ** mB], "dEq2 result"];
assert[verifiedQ[dEq2], "dEq2 verified"];

(* ---- graded NC Neumann inverse (the matrix Sigma^{-1}(t) lemma) ---- *)
dN = derive[inv[s - e], Grading -> {e -> 1}, GradingOrder -> 2] //
     step[expandInverse[s, e, 2]];
assert[ncSame[result[dN],
   inv[s] + inv[s] ** e ** inv[s] + inv[s] ** e ** inv[s] ** e ** inv[s]], "dN result"];
assert[relationOf[dN] === AsymEqual, "dN relation"];
assert[stepsOf[dN][[1]]["cert"]["status"] === "Verified", "dN verified (order probe)"];

(* ---- over-truncation refuted: claim inv[s] ~ inv[s-e] to order 2 ---- *)
dNbad = Quiet@step[
   derive[inv[s - e], Grading -> {e -> 1}, GradingOrder -> 2],
   Function[cur, Yields[inv[s], AsymEqual, "drop too much"]]];
assert[stepsOf[dNbad][[1]]["cert"]["status"] === "Refuted", "dNbad refuted"];

(* ---- symmetric / antisymmetric split ---- *)
ncDeclare[A1];
assert[ncSame[symPart[A1] + antiPart[A1], A1], "sym+anti = A1"];
assert[ncSame[symPart[A1], (A1 + tp[A1])/2], "symPart"];

(* ---- quadratic form vanishes under a side relation (exponential-prefactor move) ----
   w^T (A1 + A1^T) w = 0  given  A1 w = 0. Verified by random A1, w with A1.w = 0. *)
ncDeclareVec[w];
rels = {A1 ** w -> 0, tp[w] ** tp[A1] -> 0};
dPref = derive[tp[w] ** (A1 + tp[A1]) ** w, Relations -> rels] //
        step[NCExpand] //
        step[applyRel[rels]];
assert[result[dPref] === 0, "prefactor vanishes"];
assert[verifiedQ[dPref], "prefactor verified under A1 w = 0"];

(* ---- refuted: claim w^T A1 w == w^T w; false, since w^T A1 w = 0 under A1 w = 0 ---- *)
dPrefBad = Quiet@step[
   derive[tp[w] ** A1 ** w, Relations -> {A1 ** w -> 0}],
   Function[cur, tp[w] ** w]];
assert[stepsOf[dPrefBad][[1]]["cert"]["status"] === "Refuted", "prefBad refuted"];

(* ---- scalar work is NOT misrouted to the NC path (no declared NC symbols) ---- *)
dScalar = derive[(p + q)^2] // step[rewrite[(p + q)^2 -> p^2 + 2 p q + q^2]];
assert[verifiedQ[dScalar], "scalar not misrouted"];

Print["ALL TESTS PASSED (", $passed, " assertions)"];
