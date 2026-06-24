(* ::Package:: *)

(* Calculemus formal-sum self-checks (held Inactive[Sum]).
   Standalone:  wolframscript -file Tests/SumsTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "TestHarness.wl"}]];
suite["Sums"];

(* ============================================================ *)
section["constructor & linearity"];
test["sum constructor", sum[f[k], {k, 0, 3}] === Inactive[Sum][f[k], {k, 0, 3}]];
dL = derive[sum[c k + k^2, {k, 0, 5}]] // step[sumLinearity];
test["split over addends", FreeQ[result[dL], Inactive[Sum][_Plus, _]]];
test["pulled out index-free factor", FreeQ[result[dL], Inactive[Sum][c k, _]]];
test["sum linearity verified", verifiedQ[dL]];

(* ============================================================ *)
section["index surgery (concrete bounds)"];
dR = derive[sum[k^2, {k, 0, 3}]] // step[shiftIndex[2]];
test["shiftIndex verified", verifiedQ[dR]];
dS = derive[sum[k^2, {k, 0, 5}]] // step[splitSum[2]];
test["splitSum verified", verifiedQ[dS]];
test["splitSum produced two sums", Length[Cases[result[dS], Inactive[Sum][__], Infinity]] === 2];
dPf = derive[sum[k^2, {k, 1, 5}]] // step[peelFirst];
test["peelFirst verified", verifiedQ[dPf]];
dPl = derive[sum[k^2, {k, 1, 5}]] // step[peelLast];
test["peelLast verified", verifiedQ[dPl]];
dF = derive[Inactive[Sum][Inactive[Sum][i j, {j, 0, 3}], {i, 0, 2}]] // step[swapSum];
test["swapSum (Fubini) verified", verifiedQ[dF]];
dG = derive[c sum[k, {k, 0, 5}] + sum[k^2, {k, 0, 5}]] // step[gather];
test["gather combines same-range sums verified", verifiedQ[dG]];

dBad = Quiet@step[derive[sum[k^2, {k, 0, 3}]],
   Function[cur, cur /. Inactive[Sum][f_, {k_, a_, b_}] :> Inactive[Sum][f, {k, a + 2, b + 2}]]];
test["shifting bounds without adjusting summand Refuted", statusOf[dBad] === "Refuted"];

(* ============================================================ *)
section["symbolic dimension n (concrete-n probe)"];
dN = derive[sum[k^2, {k, 1, n}]] // step[shiftIndex[1]];
test["shiftIndex over 1..n verified", verifiedQ[dN]];
dNp = derive[sum[k^2, {k, 1, n}]] // step[peelFirst];
test["peelFirst over 1..n verified", verifiedQ[dNp]];
dD = derive[Inactive[Sum][Inactive[Sum][i j, {j, 1, n}], {i, 1, n}]] // step[swapSum];
test["double sum over 1..n swap verified", verifiedQ[dD]];
dGn = derive[sum[k, {k, 1, n}] + sum[k^2, {k, 1, n}]] // step[gather];
test["gather over 1..n verified", verifiedQ[dGn]];
dBadN = Quiet@step[derive[sum[k^2, {k, 1, n}]],
   Function[cur, cur /. Inactive[Sum][f_, {k_, a_, b_}] :> Inactive[Sum][f, {k, a + 1, b + 1}]]];
test["wrong reindex over 1..n Refuted", statusOf[dBadN] === "Refuted"];

(* ============================================================ *)
section["routing: scalars are not misrouted"];
dScalar = derive[(p + q)^2] // step[rewrite[(p + q)^2 -> p^2 + 2 p q + q^2]];
test["scalar work verified", verifiedQ[dScalar]];

endSuite[];
