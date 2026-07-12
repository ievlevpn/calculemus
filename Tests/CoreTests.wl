(* ::Package:: *)

(* Calculemus Core self-checks: relations algebra, certify, the Derivation
   chain, status bookkeeping, assumption accumulation, rewrite helpers.
   Standalone:  wolframscript -file Tests/CoreTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "TestHarness.wl"}]];
suite["Core"];

(* ============================================================ *)
section["relations: flip"];
test["flip =",  flipRelation[Equal] === Equal];
test["flip <=", flipRelation[LessEqual] === GreaterEqual];
test["flip >=", flipRelation[GreaterEqual] === LessEqual];
test["flip <",  flipRelation[Less] === Greater];
test["flip >",  flipRelation[Greater] === Less];
test["flip ~",  flipRelation[AsymEqual] === AsymEqual];

(* ============================================================ *)
section["relations: compose"];
test["= is identity (left)",  composeRelation[Equal, LessEqual] === LessEqual];
test["= is identity (right)", composeRelation[Greater, Equal] === Greater];
test["<= o <= = <=", composeRelation[LessEqual, LessEqual] === LessEqual];
test["<= o <  = <",  composeRelation[LessEqual, Less] === Less];
test["<  o <= = <",  composeRelation[Less, LessEqual] === Less];
test[">= o >  = >",  composeRelation[GreaterEqual, Greater] === Greater];
test["~ o ~  = ~",   composeRelation[AsymEqual, AsymEqual] === AsymEqual];
test["<= o >= incomparable", Quiet[composeRelation[LessEqual, GreaterEqual]] === $Failed];
test["<  o >  incomparable", Quiet[composeRelation[Less, Greater]] === $Failed];
test["~  o <= incomparable", Quiet[composeRelation[AsymEqual, LessEqual]] === $Failed];

(* ============================================================ *)
section["relationLabel"];
test["label =",  relationLabel[Equal] === "="];
test["label <",  relationLabel[Less] === "<"];
test["label ~",  relationLabel[AsymEqual] === "~"];

(* ============================================================ *)
section["certify: verdicts"];
test["equality Verified", certify[(a + b)^2, a^2 + 2 a b + b^2, Equal, True]["status"] === "Verified"];
test["equality Refuted",  certify[a, a + 1, Equal, True]["status"] === "Refuted"];
test["inequality Verified", certify[x^2 + 1, x^2 + 2, LessEqual, True]["status"] === "Verified"];
test["inequality Refuted (wrong dir)", certify[x^2 + 2, x^2 + 1, LessEqual, True]["status"] === "Refuted"];
test["inequality under assumptions", certify[t, t + t^2, LessEqual, t > 0]["status"] === "Verified"];
test["true-but-hard is at least not Refuted/Unverified",
  MemberQ[{"Verified", "NumericOnly"}, certify[Exp[x], 1 + x, GreaterEqual, x > 0]["status"]]];
test["~ without grading is Unverified", certify[a, b, AsymEqual, True]["status"] === "Unverified"];
test["certify carries the relation", certify[a, a, Equal, True]["relation"] === Equal];

(* ============================================================ *)
section["derive / accessors"];
d0 = derive[a + b];
test["empty derivation result = start", result[d0] === a + b];
test["empty derivation relation = =", relationOf[d0] === Equal];
test["empty derivation verified (vacuous)", verifiedQ[d0]];
test["assumptions default True", assumptionsOf[d0] === True];
test["assumptions list -> And", assumptionsOf[derive[x, Assumptions -> {x > 0, x < 1}]] === (x > 0 && x < 1)];
test["stepsOf empty = {}", stepsOf[d0] === {}];

(* ============================================================ *)
section["step: verified equality"];
d1 = derive[(a + b)^2] // step[rewrite[(a + b)^2 -> a^2 + 2 a b + b^2]];
test["result", same[result[d1], a^2 + 2 a b + b^2]];
test["relation =", relationOf[d1] === Equal];
test["verified", verifiedQ[d1]];
test["one step recorded", Length[stepsOf[d1]] === 1];
test["note default empty", stepsOf[d1][[1]]["note"] === ""];
d1n = derive[a (a + 2 b)] // step[rewrite[a (a + 2 b) -> a^2 + 2 a b], "expand"];
test["note recorded", stepsOf[d1n][[1]]["note"] === "expand"];

(* ============================================================ *)
section["step: refutation is recorded, not thrown"];
d2 = Quiet@step[derive[a], rewrite[a -> a + 1]];
test["status Refuted", statusOf[d2] === "Refuted"];
test["not verified", ! verifiedQ[d2]];
test["step still recorded", Length[stepsOf[d2]] === 1];

(* ============================================================ *)
section["step: inequality chain + composition"];
d3 = derive[x^2 + y^2 + 1] // step[dropTerm[x^2]];
test["drop term result", same[result[d3], y^2 + 1]];
test["drop term relation >=", relationOf[d3] === GreaterEqual];
test["drop term verified", verifiedQ[d3]];
d6 = derive[(p + q)^2 + r^2] //
     step[rewrite[(p + q)^2 -> p^2 + 2 p q + q^2]] //
     step[dropTerm[r^2]];
test["= then >= composes to >=", relationOf[d6] === GreaterEqual];
test["two-step chain verified", verifiedQ[d6]];
test["two steps recorded", Length[stepsOf[d6]] === 2];

(* ============================================================ *)
section["step: assumed -> Asserted overrides refutation"];
dA = step[derive[x], Function[cur, Yields[x + 1, Equal, "", <|"assumed" -> True|>]]];
test["assumed step is Asserted (not Refuted)", statusOf[dA] === "Asserted"];
test["Asserted counts as verified-enough", verifiedQ[dA]];

(* ============================================================ *)
section["step: side-conditions accumulate / contradict"];
dCond = step[derive[x], Function[cur, Yields[x, Equal, "", <|"conditions" -> (y > 0)|>]]];
test["condition accumulated into assumptions", assumptionsOf[dCond] === (y > 0)];
dContra = Quiet@step[derive[x, Assumptions -> x > 0],
   Function[cur, Yields[x, Equal, "", <|"conditions" -> (x < 0)|>]]];
test["contradictory condition -> Refuted", statusOf[dContra] === "Refuted"];

(* ============================================================ *)
section["rewrite / at helpers"];
test["rewrite[rule] is a function", rewrite[a -> b][a + c] === b + c];
test["at by single position", at[a + b + c, {2}, f] === a + f[b] + c];
test["at by many positions", at[a + b + c, {{1}, {3}}, f] === f[a] + b + f[c]];
test["at by pattern", same[at[x^2 + y^2, _Symbol^2, g], g[x^2] + g[y^2]] ||
   at[x^2 + y^2, _Symbol^2, g] === g[x^2] + g[y^2]];

(* ============================================================ *)
section["signed probes & no-op honesty"];
test["Sqrt[x^2] == x is Refuted without assumptions",
  Quiet[certify[Sqrt[x^2], x, Equal, True]]["status"] === "Refuted"];
test["Sqrt[x^2] == x is Verified under x >= 0",
  certify[Sqrt[x^2], x, Equal, x >= 0]["status"] === "Verified"];
test["refuted numeric verdict carries a counterexample witness",
  AssociationQ[Quiet[certify[Abs[y], y, Equal, True]]["numeric"]["witness"]]];
dNoop = Quiet@step[derive[(nx + ny)^2], rewrite[(nx + nq)^3 -> 0]];
test["no-op transform records no step", stepsOf[dNoop] === {}];
test["no-op leaves the expression as the start", result[dNoop] === (nx + ny)^2];

endSuite[];
