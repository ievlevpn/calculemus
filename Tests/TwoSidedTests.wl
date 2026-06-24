(* ::Package:: *)

(* Calculemus two-sided (in)equation self-checks (apply the same op to both sides,
   verified as an implication). Standalone:  wolframscript -file Tests/TwoSidedTests.wl *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "TestHarness.wl"}]];
suite["TwoSided"];

(* ============================================================ *)
section["relate constructors & accessors"];
r0 = relate[x, LessEqual, y];
test["lhsOf", lhsOf[r0] === x];
test["rhsOf", rhsOf[r0] === y];
test["relationOf", relationOf[r0] === LessEqual];
test["relational-head form", relate[x <= y] === relate[x, LessEqual, y]];
test["empty is vacuously verified", verifiedQ[r0]];

(* ============================================================ *)
section["operations preserving the relation"];
dAdd = relate[x, LessEqual, y] // stepBoth[addBoth[c], "add c"];
test["addBoth result", same[lhsOf[dAdd], x + c] && same[rhsOf[dAdd], y + c]];
test["addBoth verified", verifiedQ[dAdd]];
dSub = relate[x, LessEqual, y] // stepBoth[subtractBoth[c]];
test["subtractBoth result", same[lhsOf[dSub], x - c] && same[rhsOf[dSub], y - c]];
test["subtractBoth verified", verifiedQ[dSub]];
(* rewriteBoth must preserve each side's value (relation unchanged), so a proper
   use rewrites via an algebraic identity *)
dRw = relate[(a + 1)^2, LessEqual, M] // stepBoth[rewriteBoth[(a + 1)^2 -> a^2 + 2 a + 1]];
test["rewriteBoth result", same[lhsOf[dRw], a^2 + 2 a + 1] && rhsOf[dRw] === M];
test["rewriteBoth (value-preserving) verified", verifiedQ[dRw]];

(* ============================================================ *)
section["multiplication: sign-aware flipping"];
dMulP = relate[x, LessEqual, y, Assumptions -> k > 0] // stepBoth[mulBoth[k]];
test["mulBoth by positive keeps relation", relationOf[dMulP] === LessEqual];
test["mulBoth positive verified", verifiedQ[dMulP]];
dMulN = relate[x, LessEqual, y] // stepBoth[mulBoth[-2]];
test["mulBoth by negative flips relation", relationOf[dMulN] === GreaterEqual];
test["mulBoth flip verified", verifiedQ[dMulN]];

(* ============================================================ *)
section["applyBoth: monotonicity"];
d = relate[Log[P], LessEqual, B] // stepBoth[applyBoth[Exp], "exponentiate"];
test["exp lhs", same[lhsOf[d], P] || same[lhsOf[d], Exp[Log[P]]]];
test["exp rhs", same[rhsOf[d], Exp[B]]];
test["exp preserves relation (increasing)", relationOf[d] === LessEqual];
test["exponentiation verified", verifiedQ[d]];
dDec = relate[x, LessEqual, y, Assumptions -> x > 0 && y > 0] //
       stepBoth[applyBoth[1/# &, "Decreasing"]];
test["decreasing map flips relation", relationOf[dDec] === GreaterEqual];
test["decreasing map verified", verifiedQ[dDec]];

(* ============================================================ *)
section["implication verification catches bad steps"];
dBad = Quiet@stepBoth[relate[x, LessEqual, y], applyBoth[#^2 &]];
test["non-monotone square (all reals) Refuted", statusOf[dBad] === "Refuted"];
dOk = relate[x, LessEqual, y, Assumptions -> 0 <= x] // stepBoth[applyBoth[#^2 &], "square (x>=0)"];
test["square verified under nonnegativity", verifiedQ[dOk]];

endSuite[];
