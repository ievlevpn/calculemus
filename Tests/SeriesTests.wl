(* ::Package:: *)

(* Calculemus series / graded-asymptotics self-checks.
   Standalone:  wolframscript -file Tests/SeriesTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "TestHarness.wl"}]];
suite["Series"];

(* ============================================================ *)
section["grading spec & monomial weight"];
test["normalizeGrading list of symbols", normalizeGrading[{x, y}] === {x -> 1, y -> 1}];
test["normalizeGrading mixed", normalizeGrading[{x, y -> 2}] === {x -> 1, y -> 2}];
test["normalizeGrading bare rule", normalizeGrading[e -> 1] === {e -> 1}];
test["normalizeGrading bare symbol", normalizeGrading[e] === {e -> 1}];
test["monomialWeight weight-1", monomialWeight[x^3, {x, y}] === 3];
test["monomialWeight weighted", monomialWeight[x^2 y, {x -> 1, y -> 2}] === 4];

(* ============================================================ *)
section["truncate by weighted degree"];
test["int deg 1", same[truncate[1 + x + y + x y + x^2, {x, y}, 1], 1 + x + y]];
test["int deg 2", same[truncate[1 + x + y + x y + x^2, {x, y}, 2], 1 + x + y + x y + x^2]];
test["frac 1/2", same[truncate[1 + x + y + x y, {x -> 1/2, y -> 1/2}, 1/2], 1 + x + y]];
test["frac 1", same[truncate[1 + x + y + x y, {x -> 1/2, y -> 1/2}, 1], 1 + x + y + x y]];
test["symbolic beta weight",
  same[truncate[c0 + c1 t^\[Beta] + c2 t^(2 \[Beta]), {t}, \[Beta], \[Beta] > 0], c0 + c1 t^\[Beta]]];
test["undecided comparison keeps term (conservative)",
  same[Quiet@truncate[1 + x^p, {x}, q], 1 + x^p]];

(* ============================================================ *)
section["series expansion"];
test["scalar Neumann", same[seriesExpand[1/(\[Sigma] - e), {e -> 1}, 2],
  1/\[Sigma] + e/\[Sigma]^2 + e^2/\[Sigma]^3]];
test["exp series", same[seriesExpand[Exp[x], {x}, 3], 1 + x + x^2/2 + x^3/6]];
test["log series", same[seriesExpand[Log[1 + x], {x}, 3], x - x^2/2 + x^3/3]];
test["symbolic-order falls back to truncation",
  same[seriesExpand[1 + x + x^2, {x}, 1], 1 + x]];

(* ============================================================ *)
section["o / O markers"];
test["littleO idempotent", littleO[s] + littleO[s] === littleO[s]];
test["littleO absorbs nonzero numeric", 3 littleO[s] === littleO[s]];
test["bigO idempotent", bigO[s] + bigO[s] === bigO[s]];
test["bigO absorbs littleO", littleO[s] + bigO[s] === bigO[s]];

(* ============================================================ *)
section["verified / refuted ~ steps"];
dN = derive[1/(\[Sigma] - e), Assumptions -> \[Sigma] > 0,
            Grading -> {e -> 1}, GradingOrder -> 2] // step[dropHigherOrder[{e -> 1}, 2]];
test["result", same[result[dN], 1/\[Sigma] + e/\[Sigma]^2 + e^2/\[Sigma]^3]];
test["relation ~", relationOf[dN] === AsymEqual];
test["Verified", statusOf[dN] === "Verified"];

dCtx = derive[1/(\[Sigma] - e), Assumptions -> \[Sigma] > 0,
             Grading -> {e -> 1}, GradingOrder -> 2] // step[dropHigherOrder[]];
test["context-aware dropHigherOrder[] reads grading",
  same[result[dCtx], 1/\[Sigma] + e/\[Sigma]^2 + e^2/\[Sigma]^3]];
test["context-aware Verified", statusOf[dCtx] === "Verified"];

dBad = Quiet@step[derive[1/(\[Sigma] - e), Assumptions -> \[Sigma] > 0,
          Grading -> {e -> 1}, GradingOrder -> 2],
   Function[cur, Yields[1/\[Sigma], AsymEqual, "drop too much"]]];
test["dropping too much Refuted", statusOf[dBad] === "Refuted"];

dU = Quiet@step[derive[1/(\[Sigma] - e)],
   Function[cur, Yields[1/\[Sigma] + e/\[Sigma]^2, AsymEqual]]];
test["~ without grading stays Unverified", statusOf[dU] === "Unverified"];

endSuite[];
