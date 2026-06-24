(* ::Package:: *)

(* FormalCalc subexpression-addressing self-checks.
     wolframscript -file Tests/SubexprTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "FormalCalc.wl"}]];

ClearAll[assert];
SetAttributes[assert, HoldFirst];
assert[cond_, label_: ""] := If[TrueQ[cond], $passed++,
  Print["FAILED: ", label, " :: ", HoldForm[cond]]; Exit[1]];
$passed = 0;
same[x_, y_] := TrueQ[Simplify[x - y] === 0] || x === y;

(* ---- partOf: confirm what we are pointing at ---- *)
assert[partOf[dint[x^2 + x, {x, 0, 1}], integrand] === x^2 + x, "partOf integrand"];
assert[partOf[Exp[-(a/2) x^2 + b x], argOf[Exp]] === -(a/2) x^2 + b x, "partOf argOf[Exp]"];
assert[partOf[a/b, denominator] === b, "partOf denominator"];
assert[partOf[Log[1 + z], argOf[Log]] === 1 + z, "partOf argOf[Log]"];
assert[partOf[p + q + r, term[2]] === q, "partOf term[2]"];

(* ---- on the integrand, factor ---- *)
dI = derive[dint[x^2 + 2 x + 1, {x, 0, 1}]] // step[on[integrand, Factor]];
assert[same[partOf[result[dI], integrand], (1 + x)^2], "factored integrand"];
assert[verifiedQ[dI], "on[integrand, Factor] verified"];

(* ---- complete the square INSIDE the exponential (the Gaussian move) ---- *)
dE = derive[Exp[-(a/2) x^2 + b x], Assumptions -> a > 0] // step[on[argOf[Exp], completeSquare[x]]];
assert[! FreeQ[result[dE], (x - b/a)^2 | (x + (-(b/a)))^2], "square completed in exponent"];
assert[verifiedQ[dE], "on[argOf[Exp], completeSquare] verified"];

(* ---- operate on the 2nd term only ---- *)
dT = derive[u + (m + n)^2] // step[on[term[2], Expand]];
assert[same[result[dT], u + m^2 + 2 m n + n^2], "expanded 2nd term only"];
assert[verifiedQ[dT], "on[term[2], Expand] verified"];

(* ---- pattern locator: factor every square ---- *)
dP = derive[(p + q)^2 + (r + s)^2] // step[on[(_Plus)^2, Expand]];
assert[verifiedQ[dP], "on[pattern, Expand] verified"];
assert[FreeQ[result[dP], (_Plus)^2], "all squares expanded"];

(* ---- a bound applied to a subterm: wrong direction is caught ----
   enlarging the denominator (d -> 2d) SHRINKS 1/d, so asserting 1/d <= 1/(2d)
   is false; the verifier must refuse it (direction flips through a denominator). *)
dBad = Quiet@step[derive[1/d, Assumptions -> d > 0], on[denominator, boundBy[2 d, LessEqual]]];
assert[stepsOf[dBad][[1]]["cert"]["status"] === "Refuted", "denominator bound direction caught"];

(* ---- highlight produces a valid (boxable) expression ---- *)
assert[FreeQ[highlight[dint[x^2, {x, 0, 1}], integrand], $Failed], "highlight ok"];

Print["ALL TESTS PASSED (", $passed, " assertions)"];
