(* ::Package:: *)

(* FormalCalc Gaussian-pack self-checks.
     wolframscript -file Tests/GaussianTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "FormalCalc.wl"}]];

ClearAll[assert];
SetAttributes[assert, HoldFirst];
assert[cond_, label_: ""] := If[TrueQ[cond], $passed++,
  Print["FAILED: ", label, " :: ", HoldForm[cond]]; Exit[1]];
$passed = 0;

(* ---- scalar complete the square ---- *)
dCS = derive[al x^2 + be x + ga] // step[completeSquare[x]];
assert[verifiedQ[dCS], "complete square verified"];

(* ---- refuted: completion that drops the constant ---- *)
dCSbad = Quiet@step[derive[al x^2 + be x + ga], Function[cur, al (x + be/(2 al))^2]];
assert[stepsOf[dCSbad][[1]]["cert"]["status"] === "Refuted", "bad completion refuted"];

(* ---- Gaussian integral normalization ---- *)
dGI = derive[Inactive[Integrate][Exp[-a x^2 + m x], {x, -Infinity, Infinity}]] //
      step[gaussianIntegral];
assert[FreeQ[result[dGI], Inactive], "integral evaluated to closed form"];
assert[verifiedQ[dGI], "gaussian integral verified"];

(* ---- matrix complete the square, A symmetric (mean-shift in the exponent) ---- *)
ncDeclareSym[capA]; ncDeclareVec[cc, xx];
dMCS = derive[gaussQuadForm[capA, cc, xx]] // step[gaussCompleteSquare[capA, cc, xx] &];
assert[verifiedQ[dMCS], "matrix complete square verified (symmetric A)"];

(* ---- the symmetry matters: completing as if symmetric is refuted for a generic (non-sym) A ---- *)
ncDeclare[genA];
dMCSbad = Quiet@step[derive[gaussQuadForm[genA, cc, xx]],
   Function[cur, gaussCompleteSquare[genA, cc, xx]]];
assert[stepsOf[dMCSbad][[1]]["cert"]["status"] === "Refuted", "non-symmetric completion refuted"];

Print["ALL TESTS PASSED (", $passed, " assertions)"];
