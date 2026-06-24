(* ::Package:: *)

(* FormalCalc formal-sum self-checks.
     wolframscript -file Tests/SumsTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "FormalCalc.wl"}]];

ClearAll[assert];
SetAttributes[assert, HoldFirst];
assert[cond_, label_: ""] := If[TrueQ[cond], $passed++,
  Print["FAILED: ", label, " :: ", HoldForm[cond]]; Exit[1]];
$passed = 0;

(* ---- linearity: split sum + pull out index-free factor ---- *)
dL = derive[sum[c k + k^2, {k, 0, 5}]] // step[sumLinearity];
assert[FreeQ[result[dL], Inactive[Sum][_Plus, _]], "sum linearity split"];
assert[verifiedQ[dL], "sum linearity verified"];

(* ---- reindex (shift index by 2, summand adjusted) ---- *)
dR = derive[sum[k^2, {k, 0, 3}]] // step[shiftIndex[2]];
assert[verifiedQ[dR], "shiftIndex verified"];

(* ---- split range ---- *)
dS = derive[sum[k^2, {k, 0, 5}]] // step[splitSum[2]];
assert[verifiedQ[dS], "splitSum verified"];

(* ---- swap nested sums (Fubini) ---- *)
dF = derive[Inactive[Sum][Inactive[Sum][i j, {j, 0, 3}], {i, 0, 2}]] // step[swapSum];
assert[verifiedQ[dF], "swapSum verified"];

(* ---- refuted: shift bounds but FORGET to adjust the summand ---- *)
dBad = Quiet@step[derive[sum[k^2, {k, 0, 3}]],
   Function[cur, cur /. Inactive[Sum][f_, {k_, a_, b_}] :> Inactive[Sum][f, {k, a + 2, b + 2}]]];
assert[stepsOf[dBad][[1]]["cert"]["status"] === "Refuted", "bad reindex refuted"];

(* ---- scalar work still routes correctly (no Inactive heads) ---- *)
dScalar = derive[(p + q)^2] // step[rewrite[(p + q)^2 -> p^2 + 2 p q + q^2]];
assert[verifiedQ[dScalar], "scalar not misrouted"];

Print["ALL TESTS PASSED (", $passed, " assertions)"];
