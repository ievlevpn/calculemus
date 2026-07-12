(* ::Package:: *)

(* Calculemus natural-syntax self-checks (tactic mode, verbs, >op> operator).
   Standalone:  wolframscript -file Tests/SyntaxTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "TestHarness.wl"}]];
suite["Syntax"];

(* ============================================================ *)
section["tactic mode: compute / by / goal"];
compute[(a + b)^2];
by[rewrite[(a + b)^2 -> a^2 + 2 a b + b^2]];
by[drop[a^2]];
test["two steps recorded", Length[stepsOf[goal[]]] === 2];
test["chain relation >=", relationOf[goal[]] === GreaterEqual];
test["chain verified", verifiedQ[goal[]]];
undo[];
test["undo removes a step", Length[stepsOf[goal[]]] === 1];

(* ============================================================ *)
section["the zeta(4) integral, end to end"];
compute[Inactive[Integrate][x^3/(E^x - 1), {x, 0, Infinity}], Assumptions -> x > 0];
by[rewrite[1/(E^x - 1) -> Inactive[Sum][E^(-k x), {k, 1, Infinity}]]];
by[fubini];
by[evaluate];
test["result Pi^4/15", result[goal[]] === Pi^4/15];
test["fully verified", verifiedQ[goal[]]];

(* ============================================================ *)
section["named-inequality verbs"];
compute[Sqrt[u v]];
by[amgm[u, v]];
test["amgm verb result", result[goal[]] === (u + v)/2];
test["amgm verb verified", verifiedQ[goal[]]];
test["amgm verb conditions", assumptionsOf[goal[]] === (u >= 0 && v >= 0)];

compute[1 + a];
by[expBound[a]];
test["expBound verb verified", verifiedQ[goal[]] && result[goal[]] === Exp[a]];

compute[Abs[p + q]];
by[triangleIneq[p, q]];
test["triangleIneq verb verified", verifiedQ[goal[]]];

(* ============================================================ *)
section["bound verbs"];
compute[t, Assumptions -> t > 0];
by[atMost[t + t^2]];
test["atMost <= verified", relationOf[goal[]] === LessEqual && verifiedQ[goal[]]];
compute[t + t^2, Assumptions -> t > 0];
by[atLeast[t]];
test["atLeast >= verified", relationOf[goal[]] === GreaterEqual && verifiedQ[goal[]]];

(* ============================================================ *)
section["let / restore verb"];
compute[(m + n)^2 + (m + n)];
by[let[s, m + n]];
by[rewrite[s^2 + s -> s (s + 1)]];
test["let verb verified", verifiedQ[goal[]]];

(* ============================================================ *)
section[">op> chaining operator"];
dChain = derive[(p + q)^2] \[RightTriangle] rewrite[(p + q)^2 -> p^2 + 2 p q + q^2] \[RightTriangle] drop[p^2];
test[">op> chain relation >=", relationOf[dChain] === GreaterEqual];
test[">op> chain verified", verifiedQ[dChain]];

(* ============================================================ *)
section["two-sided in tactic mode"];
compute[Log[P] <= B];
by[applyBoth[Exp], "exponentiate both sides"];
test["two-sided tactic result", rhsOf[goal[]] === Exp[B]];
test["two-sided tactic verified", verifiedQ[goal[]]];

(* ============================================================ *)
section["claim / caveats"];
compute[c0 + dint[g[x], {x, -1, 1}]];
by[claim[dint[g[x], {x, -1, 1}] -> 0], "odd function integrates to 0"];
test["claim rewrote the integral", result[goal[]] === c0];
test["claim is Asserted", lastStatus[goal[]] === "Asserted"];
test["caveats reports the claim (Framed)", Head[caveats[]] === Framed];

compute[1/(ss - ee)];
by[Function[cur, Yields[1/ss + ee/ss^2, AsymEqual]], "no grading -> unverified"];
test["unverified step recorded", lastStatus[goal[]] === "Unverified"];
test["caveats reports the unverified step", Head[caveats[]] === Framed];

compute[(a + b)^2];
by[rewrite[(a + b)^2 -> a^2 + 2 a b + b^2]];
test["no caveats when fully verified", Head[caveats[]] === Style];

(* ============================================================ *)
section["search loop: refusal, assuming, natural input, discovery"];
compute[sa + sb, Assumptions -> {sa > 0, sb > 0}];
Quiet@by[atMost[sa]];                       (* illegal: sa+sb <= sa *)
test["refuted move is refused: no step recorded", stepsOf[goal[]] === {}];
test["refuted move is refused: goal unchanged", result[goal[]] === sa + sb];
by[atLeast[sa]];
test["legal move still advances", Length[stepsOf[goal[]]] === 1 && verifiedQ[goal[]]];

compute[Sqrt[sx^2]];
Quiet@by[rewrite[Sqrt[sx^2] -> sx]];        (* refused: needs sx >= 0 *)
test["sign-dependent rewrite refused without assumption", stepsOf[goal[]] === {}];
by[assuming[sx >= 0]];
by[rewrite[Sqrt[sx^2] -> sx]];
test["assuming[] makes it verify", verifiedQ[goal[]] && result[goal[]] === sx];
test["assuming[] accumulates the assumption", assumptionsOf[goal[]] === (sx >= 0)];

compute[Integrate[E^(-sq t), {t, 0, Infinity}], Assumptions -> sq > 1];
test["live Integrate input is held, not evaluated",
  MatchQ[result[goal[]], Inactive[Integrate][__]] && Head[goal[]] === Derivation];

compute[(sa + sb)^2];
Quiet@by[rewrite[(sa + sq)^7 -> 0]];
test["no-op by[] records nothing", stepsOf[goal[]] === {}];
test["moves[] returns a grid", Head[moves[]] === Grid];
by[rewrite[(sa + sb)^2 -> sa^2 + 2 sa sb + sb^2]];
test["changed[] highlights the difference", ! FreeQ[changed[], Framed]];

endSuite[];
