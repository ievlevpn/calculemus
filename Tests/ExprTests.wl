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

same[x_, y_] := TrueQ[Simplify[x - y] === 0] || x === y;

(* ---- abbreviation: name a subexpression, manipulate, restore ---- *)
dAb = derive[(p + q)^2 + (p + q)] //
      step[abbreviate[s, p + q], "let s = p+q"] //
      step[rewrite[s^2 + s -> s (s + 1)], "factor"] //
      step[restore[s], "restore s"];
assert[same[result[dAb], (p + q) (p + q + 1)], "abbreviation result"];
assert[verifiedQ[dAb], "abbreviation chain verified"];
assert[definitionsOf[dAb] === {s -> p + q}, "definition recorded"];

(* ---- the intermediate expression is genuinely in terms of s ---- *)
assert[! FreeQ[stepsOf[dAb][[2]]["result"], s], "middle step is written in s"];

(* ---- a wrong manipulation under an abbreviation is still caught ---- *)
dAbBad = Quiet@step[derive[(p + q)^2] // step[abbreviate[s, p + q]],
   rewrite[s^2 -> s^3]];   (* (p+q)^2 != (p+q)^3 *)
assert[stepsOf[dAbBad][[2]]["cert"]["status"] === "Refuted", "wrong step under abbreviation refuted"];

Print["ALL TESTS PASSED (", $passed, " assertions)"];
