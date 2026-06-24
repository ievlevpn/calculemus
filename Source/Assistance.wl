(* ::Package:: *)

(* FormalCalc Assistance: notebook help - argument hints, argument-count checking,
   value completions, and an input alias for the >op> operator. Loaded last.
   SyntaxInformation works everywhere; the front-end pieces (AddSpecialArgCompletion,
   input alias) run only when a notebook front-end is present. *)

setSyntax[sym_, pat_] := (SyntaxInformation[sym] = {"ArgumentsPattern" -> pat});

(* --- starting / driving a derivation --- *)
setSyntax[derive, {_, OptionsPattern[]}];
setSyntax[relate, {_, _., _.}];
setSyntax[compute, {_, ___}];
setSyntax[step, {_, _., _.}];
setSyntax[stepBoth, {_, _., _.}];
setSyntax[by, {_, _.}];
setSyntax[undo, {}];  setSyntax[goal, {}];  setSyntax[caveats, {_.}];

(* --- inspecting / addressing subexpressions --- *)
setSyntax[result, {_}];  setSyntax[relationOf, {_}];  setSyntax[verifiedQ, {_}];
setSyntax[stepsOf, {_}]; setSyntax[assumptionsOf, {_}]; setSyntax[definitionsOf, {_}];
setSyntax[on, {_, _}];  setSyntax[partOf, {_, _}];  setSyntax[highlight, {_, _}];
setSyntax[at, {_, _, _}];  setSyntax[rewrite, {_}];

(* --- held integrals / sums --- *)
setSyntax[dint, {_, _}];  setSyntax[iint, {_, _}];  setSyntax[sum, {_, _}];
setSyntax[changeVar, {_, _, _.}];  setSyntax[ibp, {_, _.}];  setSyntax[splitDomain, {_}];
setSyntax[shiftIndex, {_}];  setSyntax[splitSum, {_}];

(* --- bounds, inequalities, claims --- *)
setSyntax[signOf, {_, _.}];  setSyntax[dropTerm, {_}];  setSyntax[drop, {_}];
setSyntax[boundBy, {_, _.}];  setSyntax[boundSub, {_, _.}];
setSyntax[atMost, {_}];  setSyntax[atLeast, {_}];
setSyntax[useIneq, {_, _.}];  setSyntax[assume, {_, _., _.}];  setSyntax[claim, {_, _.}];
setSyntax[registerInequality, {_, _, _, _, OptionsPattern[]}];
setSyntax[defineInequality, {_, _, _, _, OptionsPattern[]}];
setSyntax[amgm, {_, _}];  setSyntax[triangleIneq, {_, _}];  setSyntax[young, {_, _, _, _}];
setSyntax[bernoulli, {_, _}];  setSyntax[expBound, {_}];  setSyntax[logBound, {_}];

(* --- series / matrix / gaussian --- *)
setSyntax[truncate, {_, _, _, _.}];  setSyntax[seriesExpand, {_, _, _, _.}];
setSyntax[dropHigherOrder, {___}];
setSyntax[ncDeclare, {___}];  setSyntax[ncDeclareVec, {___}];  setSyntax[ncDeclareSym, {___}];
setSyntax[neumannInverse, {_, _, _}];  setSyntax[expandInverse, {_, _, _}];
setSyntax[quadForm, {_, _, _}];  setSyntax[completeSquareMat, {_, _, _}];
setSyntax[symPart, {_}];  setSyntax[antiPart, {_}];  setSyntax[applyRel, {___}];
setSyntax[completeSquare, {_}];  setSyntax[abbreviate, {_, _}];  setSyntax[let, {_, _}];
setSyntax[restore, {_}];  setSyntax[gaussExp, {_, _}];  setSyntax[prefactorExponent, {_, _, _, _}];
setSyntax[applyBoth, {_, _.}];  setSyntax[mulBoth, {_}];  setSyntax[addBoth, {_}];

(* --- front-end assistance: value completions + the >op> alias --- *)
installAssistance[] := If[TrueQ[$Notebooks],
  Quiet[
    (* dropdown of registered inequality names when typing useIneq["..." *)
    FE`Evaluate[FEPrivate`AddSpecialArgCompletion["useIneq" -> {Keys[$inequalities]}]];
    (* type  Esc |> Esc  to get the >op> operator *)
    CurrentValue[$FrontEnd, InputAliases] =
      DeleteDuplicates@Append[CurrentValue[$FrontEnd, InputAliases], "|>" -> "\[RightTriangle]"];
  ]; True, False];

If[TrueQ[$Notebooks], Quiet@Check[installAssistance[], Null]];
