(* ::Package:: *)

(* Calculemus Integral (Layer 1, §6): formal manipulation of integrals held as
   Inactive[Integrate]. Nothing is evaluated; transforms are pure rewrites.
   Verification is by numeric quadrature: substitute random values for the free
   parameters, map Inactive[Integrate] -> NIntegrate, and compare both sides
   (the integral analog of the random-matrix probe). Loaded in Calculemus`Private`. *)

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

(* ---- unified verification of held integrals AND/OR sums (incl. mixed, infinite,
   and symbolic ranges).  Used by both intCertify and sumCertify. ---- *)

(* bound, summation, and integration variables (excluded from free parameters) *)
inactiveVars[e_] := DeleteDuplicates@Join[
  Cases[e, (Inactive[Integrate] | Inactive[Sum])[_, {v_, _, _}] :> v, {0, Infinity}],
  Cases[e, Inactive[Integrate][_, v_Symbol] :> v, {0, Infinity}]];

(* symbols in SUM bounds must be tested at integer dimensions, not reals *)
inactiveBoundSyms[e_] := DeleteDuplicates@Cases[
  Cases[e, Inactive[Sum][_, {_, lo_, hi_}] :> {lo, hi}, {0, Infinity}],
  s_Symbol /; Context[s] =!= "System`", {0, Infinity}];

inactiveParams[e_] := Complement[
  DeleteDuplicates@Cases[e, s_Symbol /; (Context[s] =!= "System`" && ! NumericQ[s]), {0, Infinity}],
  inactiveVars[e]];

(* one numeric value at a sample point: Activate (symbolic eval, e.g. Gamma/Zeta)
   then N; failing that, map to NSum/NIntegrate. *)
inactiveSamples[before_, after_, asm_, m_] := Module[{bsyms, vparams, draw, pts},
  bsyms = inactiveBoundSyms[{before, after}];
  vparams = Complement[Union[inactiveParams[before], inactiveParams[after]], bsyms];
  draw := Join[(# -> RandomInteger[{2, 5}]) & /@ bsyms, (# -> RandomReal[{0.5, 2.5}]) & /@ vparams];
  pts = Select[Table[draw, {4 m}], (asm === True || TrueQ[asm /. #]) &];
  If[pts === {}, Table[draw, {m}], Take[pts, UpTo[m]]]];

(* numeric value of an ALREADY-activated form at a sample (cheap); only if that
   fails to numericize do we fall back to NSum/NIntegrate on the original. *)
inactiveSampleValue[activated_, orig_, pt_] := Module[{v},
  v = If[activated === $bad, $bad, Quiet@TimeConstrained[N[activated /. pt], 3, $bad]];
  If[NumericQ[v], v,
    Quiet@TimeConstrained[
      N[(orig /. pt) /. {Inactive[Sum] -> NSum, Inactive[Integrate] -> NIntegrate}], 5, $bad]]];

(* Activate each side ONCE (e.g. to Gamma/Zeta); reuse it for the symbolic equality
   check and for cheap per-sample numeric substitution. If the symbolic check
   already proves it, skip the numeric probe entirely. *)
inactiveCertify[before_, after_, rel_, asm_] := Module[{aB, aA, sz, res, pr, tol = 10.^-4},
  aB = Quiet@TimeConstrained[Activate[before], 5, $bad];
  aA = Quiet@TimeConstrained[Activate[after], 5, $bad];
  sz = rel === Equal && aB =!= $bad && aA =!= $bad &&
       TrueQ@Quiet@TimeConstrained[Simplify[aB - aA, asm] === 0, 3, False];
  If[sz,
    <|"relation" -> rel, "symbolic" -> True, "numeric" -> <|"verdict" -> Unknown|>, "status" -> "Verified"|>,
    res = DeleteCases[
      Table[Module[{bn = inactiveSampleValue[aB, before, pt], an = inactiveSampleValue[aA, after, pt]},
          If[NumericQ[bn] && NumericQ[an], numericRelHolds[rel, bn, an, tol], Indeterminate]],
        {pt, inactiveSamples[before, after, asm, 5]}],
      Indeterminate];
    pr = Which[res === {}, Unknown, MemberQ[res, False], False, True, True];
    <|"relation" -> rel, "symbolic" -> Unknown, "numeric" -> <|"verdict" -> pr|>,
      "status" -> Which[pr === False, "Refuted", pr === True, "NumericOnly", True, "Unverified"]|>]];

intCertify[before_, after_, rel_, asm_] := inactiveCertify[before, after, rel, asm];
