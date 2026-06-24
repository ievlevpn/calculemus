(* ::Package:: *)

(* FormalCalc series / graded-asymptotics self-checks.
     wolframscript -file Tests/SeriesTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "FormalCalc.wl"}]];

ClearAll[assert];
SetAttributes[assert, HoldFirst];
assert[cond_, label_: ""] := If[TrueQ[cond], $passed++,
  Print["FAILED: ", label, " :: ", HoldForm[cond]]; Exit[1]];
$passed = 0;
same[a_, b_] := TrueQ[Simplify[a - b] === 0] || a === b;

(* ---- weighted truncation: integer weights ---- *)
assert[same[truncate[1 + x + y + x y + x^2, {x, y}, 1], 1 + x + y], "trunc int deg1"];
assert[same[truncate[1 + x + y + x y + x^2, {x, y}, 2], 1 + x + y + x y + x^2], "trunc int deg2"];

(* ---- fractional weights ---- *)
assert[same[truncate[1 + x + y + x y, {x -> 1/2, y -> 1/2}, 1/2], 1 + x + y], "trunc frac 1/2"];
assert[same[truncate[1 + x + y + x y, {x -> 1/2, y -> 1/2}, 1],   1 + x + y + x y], "trunc frac 1"];

(* ---- symbolic-weight truncation (the paper's t^beta grading) ---- *)
assert[same[truncate[c0 + c1 t^\[Beta] + c2 t^(2 \[Beta]), {t}, \[Beta], \[Beta] > 0],
            c0 + c1 t^\[Beta]], "trunc symbolic beta"];

(* ---- series expansion: scalar Neumann (shadow of Lemma Sigma-inverse) ---- *)
assert[same[seriesExpand[1/(\[Sigma] - e), {e -> 1}, 2],
            1/\[Sigma] + e/\[Sigma]^2 + e^2/\[Sigma]^3], "neumann scalar"];

(* ---- series expansion: transcendental ---- *)
assert[same[seriesExpand[Exp[x], {x}, 3], 1 + x + x^2/2 + x^3/6], "exp series"];
assert[same[seriesExpand[Log[1 + x], {x}, 3], x - x^2/2 + x^3/3], "log series"];

(* ---- o / O markers ---- *)
assert[littleO[s] + littleO[s] === littleO[s], "littleO idempotent"];
assert[3 littleO[s] === littleO[s], "littleO scalar"];
assert[littleO[s] + bigO[s] === bigO[s], "littleO absorbed by bigO"];

(* ---- verified ~ step inside a derivation carrying a grading ---- *)
dN = derive[1/(\[Sigma] - e), Assumptions -> \[Sigma] > 0,
            Grading -> {e -> 1}, GradingOrder -> 2] //
     step[dropHigherOrder[{e -> 1}, 2]];
assert[same[result[dN], 1/\[Sigma] + e/\[Sigma]^2 + e^2/\[Sigma]^3], "dN result"];
assert[relationOf[dN] === AsymEqual, "dN relation"];
assert[stepsOf[dN][[1]]["cert"]["status"] === "Verified", "dN verified"];

(* ---- refuted ~ : dropping too much and claiming agreement to order 2 ---- *)
dBad = Quiet@step[
   derive[1/(\[Sigma] - e), Assumptions -> \[Sigma] > 0,
          Grading -> {e -> 1}, GradingOrder -> 2],
   Function[cur, Yields[1/\[Sigma], AsymEqual, "drop too much"]]];
assert[stepsOf[dBad][[1]]["cert"]["status"] === "Refuted", "dBad refuted"];

(* ---- ~ without a grading stays honestly Unverified ---- *)
dU = Quiet@step[derive[1/(\[Sigma] - e)],
   Function[cur, Yields[1/\[Sigma] + e/\[Sigma]^2, AsymEqual]]];
assert[stepsOf[dU][[1]]["cert"]["status"] === "Unverified", "dU unverified"];

Print["ALL TESTS PASSED (", $passed, " assertions)"];
