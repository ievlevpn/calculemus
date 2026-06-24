(* ::Package:: *)

(* FormalCalc core self-checks. Run headless:
     wolframscript -file Tests/CoreTests.wl
   Exits nonzero on first failure. *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "FormalCalc.wl"}]];

ClearAll[assert];
SetAttributes[assert, HoldFirst];
assert[cond_, label_: ""] := If[TrueQ[cond], $passed++,
  Print["FAILED: ", label, " :: ", HoldForm[cond]]; Exit[1]];
$passed = 0;

same[a_, b_] := TrueQ[Simplify[a - b] === 0] || a === b;

(* ---- relations algebra ---- *)
assert[composeRelation[LessEqual, LessEqual] === LessEqual, "<=o<="];
assert[composeRelation[Equal, LessEqual] === LessEqual, "=o<="];
assert[composeRelation[LessEqual, Less] === Less, "<=o<"];
assert[flipRelation[LessEqual] === GreaterEqual, "flip<="];
assert[Quiet[composeRelation[LessEqual, GreaterEqual]] === $Failed, "incomparable"];

(* ---- verified equality derivation ---- *)
d1 = derive[(a + b)^2] // step[rewrite[(a + b)^2 -> a^2 + 2 a b + b^2]];
assert[same[result[d1], a^2 + 2 a b + b^2], "d1 result"];
assert[relationOf[d1] === Equal, "d1 relation"];
assert[verifiedQ[d1], "d1 verified"];

(* ---- refuted equality is caught ---- *)
d2 = Quiet@step[derive[a], rewrite[a -> a + 1]];
assert[stepsOf[d2][[1]]["cert"]["status"] === "Refuted", "d2 refuted"];
assert[! verifiedQ[d2], "d2 not verified"];

(* ---- inequality chain: drop a nonnegative term (>=) ---- *)
d3 = derive[x^2 + y^2 + 1] // step[dropTerm[x^2]];
assert[same[result[d3], y^2 + 1], "d3 result"];
assert[relationOf[d3] === GreaterEqual, "d3 relation"];
assert[verifiedQ[d3], "d3 verified"];

(* ---- boundBy under assumptions (t <= t + t^2 for t>0) ---- *)
d4 = derive[t, Assumptions -> t > 0] // step[boundBy[t + t^2, LessEqual]];
assert[same[result[d4], t + t^2], "d4 result"];
assert[verifiedQ[d4], "d4 verified"];

(* ---- wrong-direction bound is refuted (t <= t/2 is false for t>0) ---- *)
d5 = Quiet@step[derive[t, Assumptions -> t > 0], boundBy[t/2, LessEqual]];
assert[stepsOf[d5][[1]]["cert"]["status"] === "Refuted", "d5 refuted"];

(* ---- multi-step chain composes relations (= then >= gives >=) ---- *)
d6 = derive[(p + q)^2 + r^2, Assumptions -> True] //
     step[rewrite[(p + q)^2 -> p^2 + 2 p q + q^2]] //
     step[dropTerm[r^2]];
assert[relationOf[d6] === GreaterEqual, "d6 relation"];
assert[verifiedQ[d6], "d6 verified"];

(* ---- sign certificates (§9.7) ---- *)
assert[signOf[x^2] === NonNegative, "sign x^2"];
assert[signOf[t, t > 0] === Positive, "sign t>0"];
assert[signOf[-u^2 - 1, u \[Element] Reals] === Negative, "sign -u^2-1"];

Print["ALL TESTS PASSED (", $passed, " assertions)"];
