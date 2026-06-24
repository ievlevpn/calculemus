(* ::Package:: *)

(* Calculemus inequality-registry self-checks.
   Standalone:  wolframscript -file Tests/InequalitiesTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "TestHarness.wl"}]];
suite["Inequalities"];

(* ============================================================ *)
section["standard inequalities: result, relation, verification"];
dAM = derive[Sqrt[u v]] // step[useIneq["amgm", {u, v}]];
test["amgm result", result[dAM] === (u + v)/2];
test["amgm relation <=", relationOf[dAM] === LessEqual];
test["amgm verified", verifiedQ[dAM]];
test["amgm accumulated conditions", assumptionsOf[dAM] === (u >= 0 && v >= 0)];

dTri = derive[Abs[a + b]] // step[useIneq["triangle", {a, b}]];
test["triangle result", result[dTri] === Abs[a] + Abs[b]];
test["triangle verified", verifiedQ[dTri]];

dYoung = derive[a b] // step[useIneq["young", {a, b, 2, 2}]];
test["young result", same[result[dYoung], a^2/2 + b^2/2]];
test["young verified", verifiedQ[dYoung]];

dExp = derive[1 + a] // step[useIneq["exp-lower", {a}]];
test["exp-lower result", result[dExp] === Exp[a]];
test["exp-lower verified", verifiedQ[dExp]];

dLog = derive[Log[1 + w]] // step[useIneq["log-upper", {w}]];
test["log-upper result", result[dLog] === w];
test["log-upper verified", verifiedQ[dLog]];

dBer = derive[(1 + x)^r] // step[useIneq["bernoulli", {x, r}]];
test["bernoulli result", same[result[dBer], 1 + r x]];
test["bernoulli relation >=", relationOf[dBer] === GreaterEqual];
test["bernoulli verified", verifiedQ[dBer]];

(* ============================================================ *)
section["condition accumulation"];
dAcc = derive[Sqrt[u v] + Log[1 + w]] //
       step[useIneq["amgm", {u, v}]] // step[useIneq["log-upper", {w}]];
test["conditions from two inequalities accumulate",
  assumptionsOf[dAcc] === (u >= 0 && v >= 0 && w > -1)];
test["accumulated chain verified", verifiedQ[dAcc]];

(* ============================================================ *)
section["registry & discovery"];
test["inequalities[] is a Grid", Head[inequalities[]] === Grid];
test["registerInequality returns its name",
  registerInequality["sq-test", Function[{z}, z^2 -> z z], Equal, (True &)] === "sq-test"];
test["unknown inequality leaves expression unchanged",
  Quiet[result[step[derive[x], useIneq["does-not-exist", {}]]]] === x];

(* ============================================================ *)
section["user-defined (Asserted) & ad-hoc"];
defineInequality["ineq-mybound", Function[{y}, f[y] -> g[y]], LessEqual, Function[{y}, {y > 0}]];
dAsserted = derive[f[t]] // step[useIneq["ineq-mybound", {t}]];
test["user inequality is Asserted", statusOf[dAsserted] === "Asserted"];
test["Asserted counts as verified-enough", verifiedQ[dAsserted]];
test["assumed inequality still accumulates conditions", assumptionsOf[dAsserted] === (t > 0)];
dInline = derive[h[s]] // step[assume[h[s] -> k[s], LessEqual, s > 0]];
test["inline assume is Asserted", statusOf[dInline] === "Asserted"];
test["inline assume accumulates condition", assumptionsOf[dInline] === (s > 0)];

(* ============================================================ *)
section["claim (unverified, taken as given)"];
dClaim = derive[c0 + I0] // step[claim[I0 -> 0]];
test["claim rewrites the piece", result[dClaim] === c0];
test["claim is Asserted", statusOf[dClaim] === "Asserted"];
dClaimVal = derive[messyThing] // step[claim[42]];
test["claim[value] asserts the whole quantity", result[dClaimVal] === 42];

(* ============================================================ *)
section["contradiction rejection"];
dBad = Quiet@step[derive[Sqrt[u v], Assumptions -> u < 0], useIneq["amgm", {u, v}]];
test["prior u<0 vs amgm's u>=0 Refuted", statusOf[dBad] === "Refuted"];
test["contradiction not verified", ! verifiedQ[dBad]];

endSuite[];
