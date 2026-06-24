(* ::Package:: *)

(* FormalCalc Integral (Layer 1, §6): formal manipulation of integrals held as
   Inactive[Integrate]. Nothing is evaluated; transforms are pure rewrites.
   Verification is by numeric quadrature: substitute random values for the free
   parameters, map Inactive[Integrate] -> NIntegrate, and compare both sides
   (the integral analog of the random-matrix probe). Loaded in FormalCalc`Private`. *)

(* constructors *)
dint[f_, {x_, a_, b_}] := Inactive[Integrate][f, {x, a, b}];
iint[f_, x_]           := Inactive[Integrate][f, x];

(* §6.1 linearity: split over sums, pull out factors free of the integration var *)
linearity := Function[cur, cur //. {
  Inactive[Integrate][s_Plus, dom_] :> (Inactive[Integrate][#, dom] & /@ s),
  Inactive[Integrate][p_Times, {var_, lo_, hi_}] /; (Select[p, FreeQ[#, var] &] =!= 1) :>
    With[{free = Select[p, FreeQ[#, var] &], dep = Select[p, ! FreeQ[#, var] &]},
      free Inactive[Integrate][dep, {var, lo, hi}]],
  Inactive[Integrate][c_, {var_, lo_, hi_}] /; FreeQ[c, var] :> c (hi - lo)
}];

(* §6.1 / §5.4 gather: the INVERSE of linearity - pull constant factors back in
   and combine integrals/sums over the same domain into a single one. *)
gather := Function[cur, cur //. {
  c_. Inactive[Integrate][f_, {x_, a_, b_}] /; (c =!= 1 && FreeQ[c, x]) :> Inactive[Integrate][c f, {x, a, b}],
  Inactive[Integrate][f_, d_] + Inactive[Integrate][g_, d_] :> Inactive[Integrate][f + g, d],
  c_. Inactive[Sum][f_, {k_, a_, b_}] /; (c =!= 1 && FreeQ[c, k]) :> Inactive[Sum][c f, {k, a, b}],
  Inactive[Sum][f_, d_] + Inactive[Sum][g_, d_] :> Inactive[Sum][f + g, d]
}];

(* §6.5 reverse the limits of integration:  Int_a^b f = - Int_b^a f. *)
reverseLimits := Function[cur,
  cur /. Inactive[Integrate][f_, {x_, a_, b_}] :> -Inactive[Integrate][f, {x, b, a}]];

(* §6.2 change of variables: old = phi(newvar). Jacobian D[phi] is inserted; new
   limits are SOLVED from phi(newvar) = old-limit (override with explicit {na,nb}). *)
changeVar[newvar_, phi_, {na_, nb_}] := Function[cur,
  cur /. Inactive[Integrate][f_, {var_, lo_, hi_}] :>
    Inactive[Integrate][(f /. var -> phi) D[phi, newvar], {newvar, na, nb}]];
changeVar::nolimit = "Could not solve `1` = `2` for the new variable; pass explicit limits.";
changeVar[newvar_, phi_] := Function[cur,
  cur /. Inactive[Integrate][f_, {var_, lo_, hi_}] :>
    Module[{sa = Quiet@Solve[phi == lo, newvar], sb = Quiet@Solve[phi == hi, newvar]},
      If[sa === {} || sb === {} || Head[sa] =!= List || Head[sb] =!= List,
        (Message[changeVar::nolimit, phi, lo]; Inactive[Integrate][f, {var, lo, hi}]),
        Inactive[Integrate][(f /. var -> phi) D[phi, newvar],
          {newvar, newvar /. First[sa], newvar /. First[sb]}]]]];

(* §6.3 integration by parts. ibp[u, v]: integrand must be u * D[v]; emits the
   boundary term u v | minus the remainder. ibp[u]: the antiderivative v of the
   rest (integrand / D... ) is COMPUTED for you. *)
ibp::mismatch = "Integrand does not equal u * D[v, x]; IBP not applied.";
ibp[u_, v_] := Function[cur,
  cur /. Inactive[Integrate][integ_, {var_, lo_, hi_}] :>
    If[Simplify[integ - u D[v, var]] === 0,
      ((u v) /. var -> hi) - ((u v) /. var -> lo) - Inactive[Integrate][D[u, var] v, {var, lo, hi}],
      (Message[ibp::mismatch]; Inactive[Integrate][integ, {var, lo, hi}])]];
ibp[u_] := Function[cur,
  cur /. Inactive[Integrate][integ_, {var_, lo_, hi_}] :>
    With[{v = Integrate[integ/u, var]},   (* v = antiderivative of dv = integrand/u *)
      ((u v) /. var -> hi) - ((u v) /. var -> lo) - Inactive[Integrate][D[u, var] v, {var, lo, hi}]]];

(* §6.5 split the domain at an interior point *)
splitDomain[c_] := Function[cur,
  cur /. Inactive[Integrate][f_, {var_, lo_, hi_}] :>
    Inactive[Integrate][f, {var, lo, c}] + Inactive[Integrate][f, {var, c, hi}]];

(* §6.8 Gaussian integral normalization (a general definite-integral identity):
     Int_{-inf}^{inf} exp(k x^2 + m x + c0) dx = sqrt(-pi/k) exp(c0 - m^2/(4k)),  k < 0. *)
gaussianIntegral := Function[cur,
  cur /. Inactive[Integrate][Exp[q_], {x_, -Infinity, Infinity}] /;
      (PolynomialQ[q, x] && Coefficient[q, x, 2] =!= 0) :>
    With[{k = Coefficient[q, x, 2], m = Coefficient[q, x, 1], c0 = Coefficient[q, x, 0]},
      Sqrt[-Pi/k] Exp[c0 - m^2/(4 k)]]];

(* §6.6 swap sum and integral (both directions; bridges to Sums). A multiplicative
   factor free of the summation index is carried through (e.g. Int x^3 Sum_k ...). *)
swapSumIntegral := Function[cur, cur /. {
  Inactive[Integrate][rest_. Inactive[Sum][f_, idx_], dom_] /; FreeQ[rest, First[idx]] :>
    Inactive[Sum][Inactive[Integrate][rest f, dom], idx],
  Inactive[Sum][rest_. Inactive[Integrate][f_, dom_], idx_] /; FreeQ[rest, First[dom]] :>
    Inactive[Integrate][Inactive[Sum][rest f, idx], dom]
}];

(* ============================================================ *)
(* Verification                                                 *)
(* ============================================================ *)
intExprQ[e_] := ! FreeQ[e, Inactive[Integrate]];

intVars[e_] := DeleteDuplicates@Join[
  Cases[e, Inactive[Integrate][_, {v_, _, _}] :> v, {0, Infinity}],
  Cases[e, Inactive[Integrate][_, v_Symbol] :> v, {0, Infinity}]];

intParams[e_] := Complement[
  DeleteDuplicates@Cases[e, s_Symbol /; (Context[s] =!= "System`" && ! NumericQ[s]), {0, Infinity}],
  intVars[e]];

(* symbolic: Activate and try to prove the difference is 0 (time-bounded) *)
intSymZero[before_, after_, asm_] := TrueQ@Quiet@TimeConstrained[
  Simplify[Activate[before] - Activate[after], asm] === 0, 5, False];

(* numeric: random params, Inactive[Integrate] -> NIntegrate, check `before rel after` *)
integralProbe[before_, after_, rel_, asm_, trials_: 6] := Module[{params, res, tol = 10.^-5},
  params = Union[intParams[before], intParams[after]];
  res = Table[
    Module[{sub = (# -> RandomReal[{0.4, 2.2}]) & /@ params, bn, an},
      Quiet@Check[
        bn = N[(before /. sub) /. Inactive[Integrate] -> NIntegrate];
        an = N[(after /. sub) /. Inactive[Integrate] -> NIntegrate];
        numericRelHolds[rel, bn, an, tol], $bad]],
    {trials}];
  res = DeleteCases[res, $bad | Indeterminate];
  Which[res === {}, Unknown, MemberQ[res, False], False, True, True]
];

(* equality is also checked symbolically (Activate); inequalities by the probe. *)
intCertify[before_, after_, rel_, asm_] := Module[{sz, pr, status},
  sz = rel === Equal && intSymZero[before, after, asm];
  pr = integralProbe[before, after, rel, asm];
  status = Which[pr === False, "Refuted", sz, "Verified", pr === True, "NumericOnly", True, "Unverified"];
  <|"relation" -> rel, "symbolic" -> If[sz, True, Unknown],
    "numeric" -> <|"verdict" -> pr|>, "status" -> status|>
];
