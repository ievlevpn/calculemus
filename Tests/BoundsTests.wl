(* ::Package:: *)

(* Calculemus bounds self-checks: sign certificates and single-quantity bounding.
   Standalone:  wolframscript -file Tests/BoundsTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "TestHarness.wl"}]];
suite["Bounds"];

(* ============================================================ *)
section["signOf certificates"];
test["even power NonNegative", signOf[x^2] === NonNegative];
test["Abs NonNegative", signOf[Abs[z]] === NonNegative];
test["zero NonNegative", signOf[0] === NonNegative];
test["t>0 Positive", signOf[t, t > 0] === Positive];
test["-t (t>0) Negative", signOf[-t, t > 0] === Negative];
test["-u^2-1 over reals Negative", signOf[-u^2 - 1, u \[Element] Reals] === Negative];
test["a+b (a>0,b>0) Positive", signOf[a + b, a > 0 && b > 0] === Positive];
test["sum of squares NonNegative", signOf[x^2 + y^2] === NonNegative];
test["unknown sign", signOf[x] === Unknown];

(* ============================================================ *)
section["dropTerm (>= step)"];
dD = derive[x^2 + y^2 + 1] // step[dropTerm[x^2]];
test["result drops the term", same[result[dD], y^2 + 1]];
test["relation >=", relationOf[dD] === GreaterEqual];
test["verified", verifiedQ[dD]];

(* ============================================================ *)
section["boundBy"];
dB = derive[t, Assumptions -> t > 0] // step[boundBy[t + t^2, LessEqual]];
test["t <= t + t^2 verified", verifiedQ[dB]];
test["relation <=", relationOf[dB] === LessEqual];
dBdef = derive[t, Assumptions -> t > 0] // step[boundBy[t + t^2]];
test["default relation is LessEqual", relationOf[dBdef] === LessEqual && verifiedQ[dBdef]];
dBge = derive[t + t^2, Assumptions -> t > 0] // step[boundBy[t, GreaterEqual]];
test["t + t^2 >= t verified", verifiedQ[dBge]];
dBbad = Quiet@step[derive[t, Assumptions -> t > 0], boundBy[t/2, LessEqual]];
test["t <= t/2 (t>0) Refuted", statusOf[dBbad] === "Refuted"];

(* ============================================================ *)
section["boundSub (bound a subterm)"];
dSub = derive[1 + x, Assumptions -> x > 0] // step[boundSub[x -> x + 1, LessEqual]];
test["1+x <= 1+(x+1) verified", verifiedQ[dSub]];
test["relation <=", relationOf[dSub] === LessEqual];
dSubBad = Quiet@step[derive[1 + x, Assumptions -> x > 0], boundSub[x -> x + 1, GreaterEqual]];
test["wrong-direction subterm bound Refuted", statusOf[dSubBad] === "Refuted"];

endSuite[];
