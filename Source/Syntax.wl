(* ::Package:: *)

(* FormalCalc Syntax: a natural, paper-like surface over the functional engine.
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
   relation) starts a two-sided derivation. Options pass through. *)
compute[(h : (Equal | LessEqual | GreaterEqual | Less | Greater))[L_, M_], opts___] :=
  (setGoal[relate[L, h, M, opts]]);
compute[e_, opts___] := setGoal[derive[e, opts]];
setGoal[d_] := ($goalHistory = {d}; d);

stepGoal[d_Derivation, op_, Automatic] := step[d, op];
stepGoal[d_Derivation, op_, note_String] := step[d, op, note];
stepGoal[d_TwoSided, op_, Automatic] := stepBoth[d, op];
stepGoal[d_TwoSided, op_, note_String] := stepBoth[d, op, note];

by::nogoal = "No active computation. Start one with compute[...].";
by[op_, note_ : Automatic] := If[$goalHistory === {},
  (Message[by::nogoal]; $Failed),
  With[{d = stepGoal[Last[$goalHistory], op, note]}, AppendTo[$goalHistory, d]; d]];

undo[] := (If[Length[$goalHistory] > 1, $goalHistory = Most[$goalHistory]]; goal[]);
goal[] := If[$goalHistory === {}, Missing["NoGoal"], Last[$goalHistory]];

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
evaluate = Activate;                      (* evaluate held integrals/sums *)
fubini = Function[cur, swapSum[swapSumIntegral[cur]]];  (* interchange sum/integral *)

(* named standard inequalities (read like mathematics) *)
amgm[a_, b_]            := useIneq["amgm", {a, b}];
triangleIneq[a_, b_]   := useIneq["triangle", {a, b}];
young[a_, b_, p_, q_]  := useIneq["young", {a, b, p, q}];
bernoulli[x_, r_]      := useIneq["bernoulli", {x, r}];
expBound[x_]           := useIneq["exp-lower", {x}];
logBound[x_]           := useIneq["log-upper", {x}];
