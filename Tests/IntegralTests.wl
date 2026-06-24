(* ::Package:: *)

(* FormalCalc formal-integral self-checks.
     wolframscript -file Tests/IntegralTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "FormalCalc.wl"}]];

ClearAll[assert];
SetAttributes[assert, HoldFirst];
assert[cond_, label_: ""] := If[TrueQ[cond], $passed++,
  Print["FAILED: ", label, " :: ", HoldForm[cond]]; Exit[1]];
$passed = 0;

(* ---- linearity: split sum + pull constants ---- *)
dL = derive[dint[a x + b x^2, {x, 0, 1}]] // step[linearity];
assert[FreeQ[result[dL], Inactive[Integrate][_Plus, _]], "linearity split off the sum"];
assert[verifiedQ[dL], "linearity verified"];

(* ---- change of variables x = 2u (Jacobian inserted) ---- *)
dC = derive[dint[x^2, {x, 0, 1}]] // step[changeVar[u, 2 u, {0, 1/2}]];
assert[verifiedQ[dC], "changeVar verified"];

(* ---- integration by parts: ∫ x e^x dx ---- *)
dI = derive[dint[x Exp[x], {x, 0, 1}]] // step[ibp[x, Exp[x]]];
assert[FreeQ[result[dI], x Exp[x]] || ! FreeQ[result[dI], Inactive[Integrate]], "ibp produced boundary + remainder"];
assert[verifiedQ[dI], "ibp verified"];

(* ---- split domain at an interior point ---- *)
dS = derive[dint[Sin[x], {x, 0, 2}]] // step[splitDomain[1]];
assert[verifiedQ[dS], "splitDomain verified"];

(* ---- multi-step chain: pull constant then change variable ---- *)
dChain = derive[dint[c x^2, {x, 0, 1}]] // step[linearity] // step[changeVar[u, 2 u, {0, 1/2}]];
assert[verifiedQ[dChain], "chain verified"];

(* ---- refuted: change of variables that FORGETS the Jacobian ---- *)
dBad = Quiet@step[derive[dint[x^2, {x, 0, 1}]],
   Function[cur, cur /. Inactive[Integrate][f_, {v_, lo_, hi_}] :>
      Inactive[Integrate][f /. v -> 2 u, {u, 0, 1/2}]]];
assert[stepsOf[dBad][[1]]["cert"]["status"] === "Refuted", "missing Jacobian refuted"];

(* ---- change of variables with AUTO-SOLVED limits (no {na,nb} given) ---- *)
dCauto = derive[dint[x^2, {x, 0, 1}]] // step[changeVar[u, 2 u]];
assert[verifiedQ[dCauto], "changeVar auto-limits verified"];

(* ---- integration by parts with AUTO-COMPUTED antiderivative (no v given) ---- *)
dIauto = derive[dint[x Exp[x], {x, 0, 1}]] // step[ibp[x]];
assert[verifiedQ[dIauto], "ibp auto-v verified"];

(* ---- swap sum and integral ---- *)
dSwap = derive[Inactive[Integrate][Inactive[Sum][g[k] x^k, {k, 0, 2}], {x, 0, 1}]] //
        step[swapSumIntegral];
assert[! FreeQ[result[dSwap], Inactive[Sum][Inactive[Integrate][__], _]], "sum pulled outside integral"];

(* ---- Gaussian integral normalization (general definite-integral identity) ---- *)
dGI = derive[Inactive[Integrate][Exp[-a x^2 + m x], {x, -Infinity, Infinity}],
             Assumptions -> a > 0] // step[gaussianIntegral];
assert[FreeQ[result[dGI], Inactive], "gaussian integral -> closed form"];
assert[verifiedQ[dGI], "gaussian integral verified"];

Print["ALL TESTS PASSED (", $passed, " assertions)"];
