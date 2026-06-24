(* ::Package:: *)

(* FormalCalc natural-syntax self-checks (tactic mode, verbs, >op> operator).
     wolframscript -file Tests/SyntaxTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "FormalCalc.wl"}]];

ClearAll[assert];
SetAttributes[assert, HoldFirst];
assert[cond_, label_: ""] := If[TrueQ[cond], $passed++,
  Print["FAILED: ", label, " :: ", HoldForm[cond]]; Exit[1]];
$passed = 0;

(* ---- tactic mode: the zeta(4) integral, paper style ---- *)
compute[Inactive[Integrate][x^3/(E^x - 1), {x, 0, Infinity}], Assumptions -> x > 0];
by[rewrite[1/(E^x - 1) -> Inactive[Sum][E^(-k x), {k, 1, Infinity}]]];
by[fubini];
by[evaluate];
assert[result[goal[]] === Pi^4/15, "tactic-mode zeta result"];
assert[verifiedQ[goal[]], "tactic-mode zeta verified"];

(* ---- undo ---- *)
compute[(a + b)^2];
by[rewrite[(a + b)^2 -> a^2 + 2 a b + b^2]];
by[drop[a^2]];
assert[Length[stepsOf[goal[]]] === 2, "two steps recorded"];
undo[];
assert[Length[stepsOf[goal[]]] === 1, "undo removed a step"];

(* ---- named inequality verb ---- *)
compute[Sqrt[u v]];
by[amgm[u, v]];
assert[result[goal[]] === (u + v)/2, "amgm verb result"];
assert[verifiedQ[goal[]], "amgm verb verified"];
assert[assumptionsOf[goal[]] === (u >= 0 && v >= 0), "amgm verb accumulated conditions"];

(* ---- atMost / atLeast verbs ---- *)
compute[t, Assumptions -> t > 0];
by[atMost[t + t^2]];
assert[relationOf[goal[]] === LessEqual && verifiedQ[goal[]], "atMost verb"];

(* ---- the >op> operator (one-cell functional chain) ---- *)
d = derive[(p + q)^2] \[RightTriangle] rewrite[(p + q)^2 -> p^2 + 2 p q + q^2] \[RightTriangle] drop[p^2];
assert[relationOf[d] === GreaterEqual, ">op> chain relation"];
assert[verifiedQ[d], ">op> chain verified"];

(* ---- two-sided in tactic mode: ln P <= B  =>  P <= e^B ---- *)
compute[Log[P] <= B];
by[applyBoth[Exp], "exponentiate both sides"];
assert[rhsOf[goal[]] === Exp[B] && verifiedQ[goal[]], "two-sided tactic mode"];

(* ---- let / restore via tactic mode ---- *)
compute[(m + n)^2 + (m + n)];
by[let[s, m + n]];
by[rewrite[s^2 + s -> s (s + 1)]];
assert[verifiedQ[goal[]], "let verb verified"];

(* ---- claim: an unverified claim mid-derivation, collected by caveats[] ---- *)
compute[c0 + dint[g[x], {x, -1, 1}]];
by[claim[dint[g[x], {x, -1, 1}] -> 0], "claim: integral of an odd function vanishes"];
assert[result[goal[]] === c0, "claim rewrote the integral to 0"];
assert[stepsOf[goal[]][[-1]]["cert"]["status"] === "Asserted", "claim is Asserted"];
assert[Head[caveats[]] === Framed, "caveats reports the claim"];

(* ---- an Unverified step is also collected ---- *)
compute[1/(ss - ee)];
by[Function[cur, Yields[1/ss + ee/ss^2, AsymEqual]], "asymptotic, no grading -> unverified"];
assert[stepsOf[goal[]][[-1]]["cert"]["status"] === "Unverified", "unverified step"];
assert[Head[caveats[]] === Framed, "caveats reports the unverified step"];

(* ---- a fully verified derivation has no caveats ---- *)
compute[(a + b)^2];
by[rewrite[(a + b)^2 -> a^2 + 2 a b + b^2]];
assert[Head[caveats[]] === Style, "no caveats when fully verified"];

Print["ALL TESTS PASSED (", $passed, " assertions)"];
