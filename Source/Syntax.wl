(* ::Package:: *)

(* Calculemus Syntax: a natural, paper-like surface over the functional engine.
   - tactic mode: compute[...] starts a page, by[...] adds a verified line, undo[]
     steps back, goal[] is the current state. Reads like margin annotations.
   - named operations / verbs so by[...] reads like mathematics.
   - the >op> (\[RightTriangle]) operator for one-cell functional chains.
   The functional core (derive / step / relate / stepBoth) is untouched. *)

(* ============================================================ *)
(* Tactic mode                                                  *)
(* ============================================================ *)
$goalHistory = {};

(* compute[expr] starts a single-quantity derivation; compute[L <= M] (any
   relation) starts a two-sided derivation. Options pass through.
   compute HOLDS its argument and inertizes live calculus heads, so the user
   can type ordinary mathematics (Integrate[...], Sum[...]) and get a held
   formal object instead of Mathematica eagerly evaluating it away. *)
SetAttributes[compute, HoldFirst];
compute[e_, opts___] := With[{ie = Inactivate[e, Integrate | Sum | Product]},
  If[MatchQ[ie, (Equal | LessEqual | GreaterEqual | Less | Greater)[_, _]],
    setGoal[relate[ie[[1]], Head[ie], ie[[2]], opts]],
    setGoal[derive[ie, opts]]]];
setGoal[d_] := ($goalHistory = {d}; d);

stepGoal[d_Derivation, op_, Automatic] := step[d, op];
stepGoal[d_Derivation, op_, note_String] := step[d, op, note];
stepGoal[d_TwoSided, op_, Automatic] := stepBoth[d, op];
stepGoal[d_TwoSided, op_, note_String] := stepBoth[d, op, note];

by::nogoal = "No active computation. Start one with compute[...].";
by::refused = "Move refused \[Dash] the claimed relation is refuted.`1` The goal is unchanged (the refused line is returned for inspection).";

(* by[] refuses a Refuted move: the goal stays where it was, like an illegal
   move in a proof assistant. The functional layer (step) still records refuted
   steps, for scripts that want the record. *)
by[op_, note_ : Automatic] := If[$goalHistory === {},
  (Message[by::nogoal]; $Failed),
  Module[{old = Last[$goalHistory], d},
    d = Quiet[stepGoal[old, op, note], {step::refuted, stepBoth::refuted}];
    If[Length[stepsOf[d]] > Length[stepsOf[old]] &&
       Last[stepsOf[d]]["cert"]["status"] === "Refuted",
      (Message[by::refused, witnessText[Last[stepsOf[d]]["cert"]]]; d),
      (AppendTo[$goalHistory, d]; d)]]];

undo[] := (If[Length[$goalHistory] > 1, $goalHistory = Most[$goalHistory]]; goal[]);
goal[] := If[$goalHistory === {}, Missing["NoGoal"], Last[$goalHistory]];
caveats[] := caveats[goal[]];   (* the current computation's unverified claims *)

(* ============================================================ *)
(* >op> chaining operator (one-cell functional style)           *)
(* ============================================================ *)
Derivation /: RightTriangle[d_Derivation, op_]          := step[d, op];
Derivation /: RightTriangle[d_Derivation, op_, rest__]  := RightTriangle[step[d, op], rest];
TwoSided   /: RightTriangle[d_TwoSided, op_]            := stepBoth[d, op];
TwoSided   /: RightTriangle[d_TwoSided, op_, rest__]    := RightTriangle[stepBoth[d, op], rest];

(* ============================================================ *)
(* Natural verbs                                                *)
(* ============================================================ *)
atMost[x_]  := boundBy[x, LessEqual];     (* "this is at most x"   (<=) *)
atLeast[x_] := boundBy[x, GreaterEqual];  (* "this is at least x"  (>=) *)
drop = dropTerm;                          (* drop a nonnegative term      *)
let[w_, expr_] := abbreviate[w, expr];    (* let w := expr                *)
fubini = Function[cur, swapSum[swapSumIntegral[cur]]];  (* interchange sum/integral *)

(* evaluate: activate held integrals/sums UNDER THE CHAIN'S ASSUMPTIONS, and
   strip ConditionalExpression conditions the assumptions already imply *)
evaluate = WithContext[Function[{expr, ctx}, Module[{act},
  act = Block[{$Assumptions = ctx["assumptions"]}, Activate[expr]];
  If[! FreeQ[act, ConditionalExpression], act = Simplify[act, ctx["assumptions"]]];
  Yields[act, Equal, "evaluate"]]]];

(* assuming[cond]: introduce an assumption MID-derivation (a search often
   realizes halfway that it needs, say, x >= 0). Affects later steps only;
   a contradictory addition is rejected by the core. *)
assuming[cond_] := Function[cur,
  Yields[cur, Equal, "assuming " <> ToString[cond, InputForm],
    <|"conditions" -> normalizeAsm[cond]|>]];

(* named standard inequalities (read like mathematics) *)
amgm[a_, b_]            := useIneq["amgm", {a, b}];
triangleIneq[a_, b_]   := useIneq["triangle", {a, b}];
young[a_, b_, p_, q_]  := useIneq["young", {a, b, p, q}];
bernoulli[x_, r_]      := useIneq["bernoulli", {x, r}];
expBound[x_]           := useIneq["exp-lower", {x}];
logBound[x_]           := useIneq["log-upper", {x}];

(* ============================================================ *)
(* moves[]: what can I do to the CURRENT goal?                  *)
(* Shape-directed discovery for the search loop - suggestions   *)
(* keyed to what the current expression contains.               *)
(* ============================================================ *)
moveRow[verb_, desc_] := {Style[verb, Bold], Style[desc, Gray]};

moves[] := If[$goalHistory === {}, (Message[by::nogoal]; $Failed), moves[goal[]]];
moves[d_] := Module[{cur = result[d], rows},
  rows = {moveRow["rewrite[lhs -> rhs]", "apply an identity you supply"],
          moveRow["on[where, op]", "apply op at a locator: integrand, summand, term[n], argOf[Exp], a pattern"],
          moveRow["let[w, expr]", "abbreviate expr as w (expanded transparently in verification)"],
          moveRow["atMost[x] / atLeast[x]", "claim a bound for the whole quantity (verified)"],
          moveRow["assuming[cond]", "add an assumption from this step on"],
          moveRow["claim[lhs -> rhs] / assume[...]", "take a step on faith (tracked by caveats[])"]};
  If[Head[cur] === Plus,
    rows = Join[rows, {moveRow["drop[term]", "drop a nonnegative term (>=)"],
                       moveRow["gather", "recombine split integrals/sums, pull factors back in"]}]];
  If[! FreeQ[cur, Inactive[Integrate]],
    rows = Join[rows, {
      moveRow["linearity", "split over sums; pull out factors free of the variable"],
      moveRow["changeVar[u, phi]", "substitute var = phi(u); Jacobian and limits handled"],
      moveRow["ibp[u]", "integrate by parts (antiderivative computed for you)"],
      moveRow["splitDomain[c] / reverseLimits", "cut or flip the integration range"],
      moveRow["gaussianIntegral", "normalize Int exp(quadratic) over the whole line"],
      moveRow["evaluate", "let Mathematica evaluate the held integrals/sums"]}]];
  If[! FreeQ[cur, Inactive[Sum]],
    rows = Join[rows, {
      moveRow["sumLinearity", "split over addends; pull out factors free of the index"],
      moveRow["shiftIndex[c] / splitSum[m] / peelFirst / peelLast", "reindex or cut the sum"],
      moveRow["evaluate", "let Mathematica evaluate the held integrals/sums"]}]];
  If[! FreeQ[cur, Inactive[Integrate]] && ! FreeQ[cur, Inactive[Sum]],
    AppendTo[rows, moveRow["fubini", "interchange the sum and the integral"]]];
  If[Head[d] === Derivation && First[d]["grading"] =!= None,
    AppendTo[rows, moveRow["dropHigherOrder[]", "expand and drop above the graded order (~)"]]];
  AppendTo[rows, moveRow["inequalities[]", "list the registered named inequalities (amgm, young, ...)"]];
  Grid[DeleteDuplicates[rows], Alignment -> Left, Spacings -> {2, 0.5}]];

(* ============================================================ *)
(* changed[]: the current line with what DIFFERS from the       *)
(* previous line boxed - "what did that step actually do?"      *)
(* ============================================================ *)
(* ponytail: positional tree diff; term reordering over-highlights *)
diffPos[a_, b_, pos_] /; a === b := {};
diffPos[a_, b_, pos_] := If[
  AtomQ[a] || AtomQ[b] || Head[a] =!= Head[b] || Length[a] =!= Length[b],
  {pos},
  Join @@ Table[diffPos[a[[i]], b[[i]], Append[pos, i]], {i, Length[a]}]];

changedFrame[e_] := Framed[e, Background -> LightYellow, FrameStyle -> Orange,
  RoundingRadius -> 3];

changed[] := If[$goalHistory === {}, (Message[by::nogoal]; $Failed), changed[goal[]]];
changed[d_Derivation] := Module[{ss = stepsOf[d], prev, cur, pos},
  If[ss === {}, Return[result[d]]];
  prev = If[Length[ss] == 1, First[d]["start"], ss[[-2]]["result"]];
  cur = Last[ss]["result"];
  pos = diffPos[prev, cur, {}];
  Which[
    pos === {},        cur,
    MemberQ[pos, {}],  changedFrame[cur],
    True, ReplacePart[cur, (# -> changedFrame[Extract[cur, #]]) & /@ pos]]];
changed[d_TwoSided] := d;   (* ponytail: two-sided diff not built; shows the object *)
