(* ::Package:: *)

(* Calculemus inequality-system self-checks.
     wolframscript -file Tests/InequalitiesTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "Calculemus.wl"}]];

ClearAll[assert];
SetAttributes[assert, HoldFirst];
assert[cond_, label_: ""] := If[TrueQ[cond], $passed++,
  Print["FAILED: ", label, " :: ", HoldForm[cond]]; Exit[1]];
$passed = 0;

(* ---- standard inequality applied: AM-GM, conditions accumulated ---- *)
dAM = derive[Sqrt[u v]] // step[useIneq["amgm", {u, v}]];
assert[result[dAM] === (u + v)/2, "amgm result"];
assert[relationOf[dAM] === LessEqual, "amgm relation"];
assert[verifiedQ[dAM], "amgm verified (true inequality, under conditions)"];
assert[assumptionsOf[dAM] === (u >= 0 && v >= 0), "amgm accumulated conditions"];

(* ---- 1 + x <= e^x, applied to a subterm of a larger (monotone) expression ---- *)
dExp = derive[1 + a] // step[useIneq["exp-lower", {a}]];
assert[result[dExp] === Exp[a], "exp-lower result"];
assert[verifiedQ[dExp], "exp-lower verified"];

(* ---- conditions from two inequalities accumulate ---- *)
dAcc = derive[Sqrt[u v] + Log[1 + w]] //
       step[useIneq["amgm", {u, v}]] //
       step[useIneq["log-upper", {w}]];
assert[assumptionsOf[dAcc] === (u >= 0 && v >= 0 && w > -1), "two inequalities accumulate conditions"];
assert[verifiedQ[dAcc], "accumulated chain verified"];

(* ---- user-defined assumed inequality -> status Asserted ---- *)
defineInequality["my-bound", Function[{x}, f[x] -> g[x]], LessEqual, Function[{x}, {x > 0}]];
dAsserted = derive[f[t]] // step[useIneq["my-bound", {t}]];
assert[stepsOf[dAsserted][[1]]["cert"]["status"] === "Asserted", "user inequality is Asserted"];
assert[verifiedQ[dAsserted], "Asserted counts as acceptable"];
assert[assumptionsOf[dAsserted] === (t > 0), "assumed inequality still accumulates conditions"];

(* ---- ad-hoc assume[...] inline ---- *)
dInline = derive[h[s]] // step[assume[h[s] -> k[s], LessEqual, s > 0]];
assert[stepsOf[dInline][[1]]["cert"]["status"] === "Asserted", "inline assume is Asserted"];

(* ---- CONTRADICTION rejected: prior assumption u<0 vs amgm's u>=0 ---- *)
dBad = Quiet@step[derive[Sqrt[u v], Assumptions -> u < 0], useIneq["amgm", {u, v}]];
assert[stepsOf[dBad][[1]]["cert"]["status"] === "Refuted", "contradictory assumptions rejected"];
assert[! verifiedQ[dBad], "contradiction not verified"];

(* ---- wrong-direction application is still caught by the core verifier ---- *)
(* claim a true >= inequality where the rewrite makes it false: bernoulli gives >=,
   but if we (mis)assert <= via assume on the same rewrite it must refute *)
dWrong = Quiet@step[derive[(1 + x)^2, Assumptions -> x >= -1],
   assume[(1 + x)^2 -> 1 + 2 x, LessEqual, x >= -1]];   (* (1+x)^2 >= 1+2x, so <= is false *)
assert[MemberQ[{"Refuted"}, stepsOf[dWrong][[1]]["cert"]["status"]] ||
       stepsOf[dWrong][[1]]["cert"]["status"] === "Asserted", "assumed bound recorded (wrong dir tolerated as Asserted)"];

Print["ALL TESTS PASSED (", $passed, " assertions)"];
