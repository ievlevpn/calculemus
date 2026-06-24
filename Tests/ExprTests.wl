(* ::Package:: *)

(* FormalCalc general expression-algebra self-checks.
     wolframscript -file Tests/ExprTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "FormalCalc.wl"}]];

ClearAll[assert];
SetAttributes[assert, HoldFirst];
assert[cond_, label_: ""] := If[TrueQ[cond], $passed++,
  Print["FAILED: ", label, " :: ", HoldForm[cond]]; Exit[1]];
$passed = 0;

(* ---- complete the square (scalar) ---- *)
dCS = derive[al x^2 + be x + ga] // step[completeSquare[x]];
assert[verifiedQ[dCS], "complete square verified"];

(* ---- refuted: a completion that drops the constant ---- *)
dCSbad = Quiet@step[derive[al x^2 + be x + ga], Function[cur, al (x + be/(2 al))^2]];
assert[stepsOf[dCSbad][[1]]["cert"]["status"] === "Refuted", "bad completion refuted"];

Print["ALL TESTS PASSED (", $passed, " assertions)"];
