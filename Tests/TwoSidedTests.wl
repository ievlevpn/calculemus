(* ::Package:: *)

(* FormalCalc two-sided (in)equation self-checks.
     wolframscript -file Tests/TwoSidedTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "FormalCalc.wl"}]];

ClearAll[assert];
SetAttributes[assert, HoldFirst];
assert[cond_, label_: ""] := If[TrueQ[cond], $passed++,
  Print["FAILED: ", label, " :: ", HoldForm[cond]]; Exit[1]];
$passed = 0;
same[x_, y_] := TrueQ[Simplify[x - y] === 0] || x === y;

(* ---- the headline: ln P <= B  =>  P <= e^B  by applying exp to both sides ---- *)
d = relate[Log[P], LessEqual, B] // stepBoth[applyBoth[Exp], "exponentiate both sides"];
assert[same[lhsOf[d], P] || same[lhsOf[d], Exp[Log[P]]], "exp lhs"];
assert[same[rhsOf[d], Exp[B]], "exp rhs"];
assert[relationOf[d] === LessEqual, "relation preserved (exp increasing)"];
assert[verifiedQ[d], "exponentiation verified"];

(* ---- add to both sides preserves the relation ---- *)
dAdd = relate[x, LessEqual, y] // stepBoth[addBoth[c], "add c"];
assert[same[lhsOf[dAdd], x + c] && same[rhsOf[dAdd], y + c], "addBoth result"];
assert[verifiedQ[dAdd], "addBoth verified"];

(* ---- multiply by a negative quantity FLIPS the relation ---- *)
dMul = relate[x, LessEqual, y, Assumptions -> True] // stepBoth[mulBoth[-2], "times -2"];
assert[relationOf[dMul] === GreaterEqual, "mulBoth by negative flips"];
assert[verifiedQ[dMul], "mulBoth flip verified"];

(* ---- multiply by a positive quantity keeps the relation ---- *)
dMulP = relate[x, LessEqual, y, Assumptions -> k > 0] // stepBoth[mulBoth[k], "times k>0"];
assert[relationOf[dMulP] === LessEqual, "mulBoth by positive keeps"];
assert[verifiedQ[dMulP], "mulBoth positive verified"];

(* ---- REFUTED: applying a non-monotone map and claiming the relation is preserved ---- *)
(* squaring is NOT order-preserving on all reals: x <= y does NOT give x^2 <= y^2 *)
dBad = Quiet@stepBoth[relate[x, LessEqual, y], applyBoth[#^2 &]];
assert[stepsOf[dBad][[1]]["cert"]["status"] === "Refuted", "non-monotone map refuted"];

(* ---- but squaring IS order-preserving for nonnegatives: verified under x>=0 ---- *)
dOk = relate[x, LessEqual, y, Assumptions -> 0 <= x] // stepBoth[applyBoth[#^2 &], "square (x>=0)"];
assert[verifiedQ[dOk], "square verified under nonnegativity"];

Print["ALL TESTS PASSED (", $passed, " assertions)"];
