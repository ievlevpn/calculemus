(* ::Package:: *)

(* Calculemus non-commutative / matrix self-checks.
   Standalone:  wolframscript -file Tests/MatrixTests.wl

   NOTE: NC symbols use unique multi-letter names with mt and vc prefixes so that,
   when every suite runs in one kernel (RunTests.wl), declaring them
   non-commutative cannot mis-route the scalar expressions used by other suites. *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "TestHarness.wl"}]];
suite["Matrix"];

ncDeclare[mtX, mtY, mtZ, mtA, mtB, mtA1, mtGen, mtS, mtE];
ncDeclareVec[vcW, vcC, vcX];
ncDeclareSym[mtSym];

(* ============================================================ *)
section["NC equality (symbolic NCExpand + random-matrix probe)"];
dEq = derive[mtX ** (mtY + mtZ)] // step[NCExpand];
test["distribute result", ncSame[result[dEq], mtX ** mtY + mtX ** mtZ]];
test["relation =", relationOf[dEq] === Equal];
test["verified", verifiedQ[dEq]];

dEq2 = derive[(mtA + mtB) ** (mtA - mtB)] // step[NCExpand];
test["non-commuting cross terms kept",
  ncSame[result[dEq2], mtA ** mtA - mtA ** mtB + mtB ** mtA - mtB ** mtB]];
test["verified (cross terms)", verifiedQ[dEq2]];

dBad = Quiet@step[derive[mtX ** mtY], (# /. mtX ** mtY -> mtY ** mtX &)];
test["commuting two matrices is Refuted", statusOf[dBad] === "Refuted"];

(* ============================================================ *)
section["graded NC Neumann inverse"];
test["neumannInverse order 1",
  ncSame[neumannInverse[mtS, mtE, 1], inv[mtS] + inv[mtS] ** mtE ** inv[mtS]]];
dN = derive[inv[mtS - mtE], Grading -> {mtE -> 1}, GradingOrder -> 2] //
     step[expandInverse[mtS, mtE, 2]];
test["expandInverse result", ncSame[result[dN],
  inv[mtS] + inv[mtS] ** mtE ** inv[mtS] + inv[mtS] ** mtE ** inv[mtS] ** mtE ** inv[mtS]]];
test["relation ~", relationOf[dN] === AsymEqual];
test["Verified (order probe)", statusOf[dN] === "Verified"];

dNbad = Quiet@step[derive[inv[mtS - mtE], Grading -> {mtE -> 1}, GradingOrder -> 2],
   Function[cur, Yields[inv[mtS], AsymEqual, "drop too much"]]];
test["over-truncation Refuted", statusOf[dNbad] === "Refuted"];

(* ============================================================ *)
section["symmetric / antisymmetric split"];
test["sym + anti = A", ncSame[symPart[mtA1] + antiPart[mtA1], mtA1]];
test["symPart formula", ncSame[symPart[mtA1], (mtA1 + tp[mtA1])/2]];
test["antiPart formula", ncSame[antiPart[mtA1], (mtA1 - tp[mtA1])/2]];

(* ============================================================ *)
section["quadratic forms under side relations"];
rels = {mtA1 ** vcW -> 0, tp[vcW] ** tp[mtA1] -> 0};
dPref = derive[tp[vcW] ** (mtA1 + tp[mtA1]) ** vcW, Relations -> rels] //
        step[NCExpand] // step[applyRel[rels]];
test["w^T(A+A^T)w vanishes under A w = 0", result[dPref] === 0];
test["verified under the relation", verifiedQ[dPref]];

dPref2 = derive[tp[vcW] ** (mtA1 + tp[mtA1]) ** vcW, Relations -> rels] //
         step[NCExpand] // step[applyRel[]];
test["context-aware applyRel[] reads relations", result[dPref2] === 0];
test["context-aware verified", verifiedQ[dPref2]];

dPrefBad = Quiet@step[derive[tp[vcW] ** mtA1 ** vcW, Relations -> {mtA1 ** vcW -> 0}],
   Function[cur, tp[vcW] ** vcW]];
test["false claim under relation Refuted", statusOf[dPrefBad] === "Refuted"];

(* ============================================================ *)
section["matrix complete-the-square (symmetry is load-bearing)"];
dMCS = derive[quadForm[mtSym, vcC, vcX]] // step[completeSquareMat[mtSym, vcC, vcX] &];
test["symmetric completion verified", verifiedQ[dMCS]];
dMCSbad = Quiet@step[derive[quadForm[mtGen, vcC, vcX]],
   Function[cur, completeSquareMat[mtGen, vcC, vcX]]];
test["non-symmetric completion Refuted", statusOf[dMCSbad] === "Refuted"];

(* ============================================================ *)
section["routing: scalars are not sent to the NC path"];
dScalar = derive[(p + q)^2] // step[rewrite[(p + q)^2 -> p^2 + 2 p q + q^2]];
test["scalar work verified", verifiedQ[dScalar]];

endSuite[];
