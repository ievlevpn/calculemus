(* ::Package:: *)

(* Calculemus subexpression-addressing self-checks (locators, partOf, on, highlight).
   Standalone:  wolframscript -file Tests/SubexprTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "TestHarness.wl"}]];
suite["Subexpr"];

(* ============================================================ *)
section["partOf: structural locators"];
test["integrand", partOf[dint[x^2 + x, {x, 0, 1}], integrand] === x^2 + x];
test["summand", partOf[sum[k^2, {k, 0, 5}], summand] === k^2];
test["argOf[Exp]", partOf[Exp[-(a/2) x^2 + b x], argOf[Exp]] === -(a/2) x^2 + b x];
test["argOf[Log]", partOf[Log[1 + z], argOf[Log]] === 1 + z];
test["argOf[Sqrt]", partOf[Sqrt[1 + w], argOf[Sqrt]] === 1 + w];
test["argOf[generic head]", partOf[g[u + v], argOf[g]] === u + v];
test["numerator", partOf[a/b, numerator] === a];
test["denominator", partOf[a/b, denominator] === b];

(* ============================================================ *)
section["partOf: positional locators"];
test["term[2]", partOf[p + q + r, term[2]] === q];
test["firstTerm", partOf[p + q + r, firstTerm] === p];
test["lastTerm", partOf[p + q + r, lastTerm] === r];
test["factor[1]", partOf[3 a b, factor[1]] === 3];
test["out-of-range term -> Missing", Head[partOf[p + q, term[9]]] === Missing];
test["term[n] on non-Plus -> Missing", Head[partOf[x^2, term[2]]] === Missing];

(* ============================================================ *)
section["partOf: pattern / concrete"];
test["pattern matches many", partOf[x^2 + y^2, _Symbol^2] === {x^2, y^2}];
test["concrete subexpression", partOf[a + b c, b c] === b c];

(* ============================================================ *)
section["on: operate at a locator (verified)"];
dI = derive[dint[x^2 + 2 x + 1, {x, 0, 1}]] // step[on[integrand, Factor]];
test["factored integrand", same[partOf[result[dI], integrand], (1 + x)^2]];
test["on[integrand, Factor] verified", verifiedQ[dI]];

dE = derive[Exp[-(a/2) x^2 + b x], Assumptions -> a > 0] // step[on[argOf[Exp], completeSquare[x]]];
test["square completed in exponent", ! FreeQ[result[dE], (x - b/a)^2 | (x + (-(b/a)))^2]];
test["on[argOf[Exp], completeSquare] verified", verifiedQ[dE]];

dT = derive[u + (m + n)^2] // step[on[term[2], Expand]];
test["expanded 2nd term only", same[result[dT], u + m^2 + 2 m n + n^2]];
test["on[term[2], Expand] verified", verifiedQ[dT]];

dP = derive[(p + q)^2 + (r + s)^2] // step[on[(_Plus)^2, Expand]];
test["all squares expanded", FreeQ[result[dP], (_Plus)^2]];
test["on[pattern, Expand] verified", verifiedQ[dP]];

dNum = derive[(a + a)/c] // step[on[numerator, Simplify]];
test["on numerator rebuilds quotient", same[result[dNum], 2 a/c]];
test["on[numerator] verified", verifiedQ[dNum]];

(* ============================================================ *)
section["on: direction & no-match"];
(* enlarging the denominator shrinks the fraction: 1/d <= 1/(2d) is false (d>0) *)
dBad = Quiet@step[derive[1/d, Assumptions -> d > 0], on[denominator, boundBy[2 d, LessEqual]]];
test["denominator bound direction caught", statusOf[dBad] === "Refuted"];
(* a locator that matches nothing warns and leaves the expression unchanged *)
dNo = Quiet@step[derive[a + b], on[integrand, Factor]];
test["no-match leaves expression unchanged", same[result[dNo], a + b]];

(* ============================================================ *)
section["highlight"];
test["highlight is boxable (no $Failed)", FreeQ[highlight[dint[x^2, {x, 0, 1}], integrand], $Failed]];
test["highlight with no match returns original", highlight[a + b, integrand] === a + b];

endSuite[];
