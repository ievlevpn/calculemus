(* ::Package:: *)

(* Calculemus formal-integral self-checks (held Inactive[Integrate], quadrature
   verification). Standalone:  wolframscript -file Tests/IntegralTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "TestHarness.wl"}]];
suite["Integral"];

(* ============================================================ *)
section["constructors"];
test["dint", dint[f[x], {x, 0, 1}] === Inactive[Integrate][f[x], {x, 0, 1}]];
test["iint", iint[f[x], x] === Inactive[Integrate][f[x], x]];

(* ============================================================ *)
section["linearity & gather"];
dL = derive[dint[a x + b x^2, {x, 0, 1}]] // step[linearity];
test["split off the sum", FreeQ[result[dL], Inactive[Integrate][_Plus, _]]];
test["pulled out the constant", FreeQ[result[dL], Inactive[Integrate][a x, _]]];
test["linearity verified", verifiedQ[dL]];
dConst = derive[dint[c, {x, 0, 1}]] // step[linearity];
test["constant integrand -> c*(b-a)", same[result[dConst], c]];
dG = derive[a dint[x, {x, 0, 1}] + b dint[x^2, {x, 0, 1}]] // step[gather];
test["gather combines same-domain integrals",
  FreeQ[result[dG], _Inactive + _Inactive] && ! FreeQ[result[dG], Inactive[Integrate]]];
test["gather verified", verifiedQ[dG]];

(* ============================================================ *)
section["change of variables"];
dC = derive[dint[x^2, {x, 0, 1}]] // step[changeVar[u, 2 u, {0, 1/2}]];
test["explicit limits verified", verifiedQ[dC]];
dCauto = derive[dint[x^2, {x, 0, 1}]] // step[changeVar[u, 2 u]];
test["auto-solved limits verified", verifiedQ[dCauto]];
dChain = derive[dint[c x^2, {x, 0, 1}]] // step[linearity] // step[changeVar[u, 2 u, {0, 1/2}]];
test["linearity then changeVar verified", verifiedQ[dChain]];
dBad = Quiet@step[derive[dint[x^2, {x, 0, 1}]],
   Function[cur, cur /. Inactive[Integrate][f_, {v_, lo_, hi_}] :>
      Inactive[Integrate][f /. v -> 2 u, {u, 0, 1/2}]]];
test["forgetting the Jacobian is Refuted", statusOf[dBad] === "Refuted"];

(* ============================================================ *)
section["integration by parts"];
dI = derive[dint[x Exp[x], {x, 0, 1}]] // step[ibp[x, Exp[x]]];
test["boundary + remainder produced",
  FreeQ[result[dI], x Exp[x]] || ! FreeQ[result[dI], Inactive[Integrate]]];
test["ibp[u,v] verified", verifiedQ[dI]];
dIauto = derive[dint[x Exp[x], {x, 0, 1}]] // step[ibp[x]];
test["ibp[u] (auto antiderivative) verified", verifiedQ[dIauto]];
dImis = Quiet@step[derive[dint[x^2, {x, 0, 1}]], ibp[x, Cos[x]]];
test["mismatched u*D[v] leaves integral unchanged",
  result[dImis] === dint[x^2, {x, 0, 1}]];

(* ============================================================ *)
section["domain & limit surgery"];
dS = derive[dint[Sin[x], {x, 0, 2}]] // step[splitDomain[1]];
test["splitDomain verified", verifiedQ[dS]];
test["splitDomain produced two integrals", Length[Cases[result[dS], Inactive[Integrate][__], Infinity]] === 2];
dR = derive[dint[Sin[x], {x, 0, 1}]] // step[reverseLimits];
test["reverseLimits verified", verifiedQ[dR]];

(* ============================================================ *)
section["Gaussian integral & sum/integral swap"];
dGI = derive[Inactive[Integrate][Exp[-a x^2 + m x], {x, -Infinity, Infinity}],
             Assumptions -> a > 0] // step[gaussianIntegral];
test["normalized to closed form", FreeQ[result[dGI], Inactive]];
test["Gaussian integral verified", verifiedQ[dGI]];
dSwap = derive[Inactive[Integrate][Inactive[Sum][g[k] x^k, {k, 0, 2}], {x, 0, 1}]] //
        step[swapSumIntegral];
test["sum pulled outside integral",
  ! FreeQ[result[dSwap], Inactive[Sum][Inactive[Integrate][__], _]]];
test["swapSumIntegral verified", verifiedQ[dSwap]];

(* ============================================================ *)
section["ibp at infinite limits & assumption-aware evaluate"];
dWat = derive[dint[E^(-uu t)/(1 + t), {t, 0, Infinity}], Assumptions -> uu > 1] //
       step[ibp[1/(1 + t)]];
test["ibp boundary at Infinity is a clean limit",
  MatchQ[result[dWat], 1/uu - Inactive[Integrate][__]]];
test["ibp at Infinity verified", verifiedQ[dWat]];
dEv = derive[dint[E^(-uu t), {t, 0, Infinity}], Assumptions -> uu > 1] // step[evaluate];
test["evaluate uses the chain's assumptions (no ConditionalExpression)",
  FreeQ[result[dEv], ConditionalExpression] && result[dEv] === 1/uu];

endSuite[];
