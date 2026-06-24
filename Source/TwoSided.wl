(* ::Package:: *)

(* FormalCalc TwoSided (Layer 1/2, §9.2): a two-sided (in)equation  L R M  that
   you transform by applying the SAME operation to both sides. This is what the
   single-quantity Derivation cannot express - e.g. from  ln P <= B  derive
   P <= e^B  by applying exp to both sides.

   Each step asserts a new relation L' R' M' that must follow from L R M; it is
   verified as an IMPLICATION: sample points where the premise L R M holds and
   check the conclusion L' R' M' there (plus a symbolic Implies check).
   Loaded in FormalCalc`Private`. *)

$relHeads = Equal | LessEqual | GreaterEqual | Less | Greater;

Options[relate] = {Assumptions -> True};
relate[L_, R_, M_, OptionsPattern[]] := TwoSided[<|
  "start" -> {L, R, M}, "lhs" -> L, "rel" -> R, "rhs" -> M,
  "assumptions" -> normalizeAsm[OptionValue[Assumptions]], "steps" -> {}|>];
relate[(h : $relHeads)[L_, M_], opts : OptionsPattern[]] := relate[L, h, M, opts];

lhsOf[TwoSided[a_]]      := a["lhs"];
rhsOf[TwoSided[a_]]      := a["rhs"];
relationOf[TwoSided[a_]] := a["rel"];
stepsOf[TwoSided[a_]]    := a["steps"];
verifiedQ[TwoSided[a_]]  := AllTrue[a["steps"], MemberQ[{"Verified", "NumericOnly", "Asserted"}, #["cert"]["status"]] &];

(* ---- operations: (L, R, M, asm) -> {L', R', M'} ---- *)
addBoth[c_]      := Function[{L, R, M, asm}, {L + c, R, M + c}];
subtractBoth[c_] := Function[{L, R, M, asm}, {L - c, R, M - c}];
mulBoth[c_]      := Function[{L, R, M, asm},
  With[{s = signOf[c, asm]},
    {L c, If[MemberQ[{Negative, NonPositive}, s], flipRelation[R], R], M c}]];
applyBoth[f_]                := Function[{L, R, M, asm}, {f[L], R, f[M]}];            (* increasing *)
applyBoth[f_, "Decreasing"]  := Function[{L, R, M, asm}, {f[L], flipRelation[R], f[M]}];
rewriteBoth[rule_]           := Function[{L, R, M, asm}, {L /. rule, R, M /. rule}];

(* ---- the step driver ---- *)
stepBoth[obj : TwoSided[a_], op_, note_ : ""] := Module[
  {L = a["lhs"], R = a["rel"], M = a["rhs"], asm = a["assumptions"], L2, R2, M2, cert, rec},
  {L2, R2, M2} = op[L, R, M, asm];
  cert = certifyImplication[L, R, M, L2, R2, M2, asm];
  If[cert["status"] === "Refuted", Message[stepBoth::refuted, Length[a["steps"]] + 1]];
  rec = <|"lhs" -> L2, "rel" -> R2, "rhs" -> M2, "note" -> note, "cert" -> cert|>;
  TwoSided[<|a, "lhs" -> L2, "rel" -> R2, "rhs" -> M2, "steps" -> Append[a["steps"], rec]|>]];
stepBoth::refuted = "Two-sided step `1` does not follow from the previous relation (Refuted).";
stepBoth[op_, note_ : ""] /; Head[op] =!= TwoSided := Function[obj, stepBoth[obj, op, note]];

(* sample over a symmetric range (the scalar probe is positive-biased, which would
   miss order-reversing counterexamples like x < 0 in  x <= y  =/=>  x^2 <= y^2). *)
twoSidedSample[{}, asm_, n_] := {{}};
twoSidedSample[vars_, asm_, n_] := Module[{pts},
  pts = Select[Table[Thread[vars -> RandomReal[{-3, 3}, Length[vars]]], {4 n}],
               (asm === True || TrueQ[asm /. #]) &];
  If[pts =!= {}, Take[pts, UpTo[n]],
    Module[{fi = Quiet@FindInstance[asm, vars, Reals]},
      If[Head[fi] === List && fi =!= {}, {Thread[vars -> (vars /. First[fi])]}, $Failed]]]];

(* ---- verify  (L R M) => (L' R' M')  ---- *)
certifyImplication[L_, R_, M_, L2_, R2_, M2_, asm_] := Module[
  {sym, vars, pts, checked = 0, passed = 0, tol = 10.^-8, status},
  sym = TrueQ@Quiet@TimeConstrained[
    Simplify[Implies[relationExpr[R, L, M], relationExpr[R2, L2, M2]], asm] === True, 4, False];
  vars = freeSymbols[{L, M, L2, M2, asm}];
  pts = twoSidedSample[vars, asm, 40];
  If[pts =!= $Failed,
    Do[Module[{lv = L /. pt, mv = M /. pt},
        If[TrueQ@Quiet@numericRelHolds[R, lv, mv, tol],          (* premise holds here *)
          checked++;
          If[TrueQ@Quiet@numericRelHolds[R2, L2 /. pt, M2 /. pt, tol], passed++]]],
      {pt, pts}]];
  status = Which[
    sym, "Verified",
    checked > 0 && passed < checked, "Refuted",
    checked > 0, "NumericOnly",
    True, "Unverified"];
  <|"relation" -> R2, "symbolic" -> sym,
    "numeric" -> <|"verdict" -> Which[checked == 0, Unknown, passed == checked, True, True, False],
                   "premiseSamples" -> checked|>, "status" -> status|>];

(* ============================================================ *)
(* Display                                                      *)
(* ============================================================ *)
twoSidedOverall[obj : TwoSided[a_]] := Which[
  AnyTrue[a["steps"], #["cert"]["status"] === "Refuted" &], "Refuted",
  AnyTrue[a["steps"], #["cert"]["status"] === "Asserted" &] && verifiedQ[obj], "Asserted",
  verifiedQ[obj], "Verified", True, "Unverified"];

relExprShow[L_, R_, M_] := Row[{L, " ", Style[relationLabel[R], Bold, GrayLevel[0.45]], " ", M}];

twoSidedGrid[a_] := Grid[
  Prepend[
    Function[s, {relExprShow[s["lhs"], s["rel"], s["rhs"]],
                 statusBadge[s["cert"]["status"]],
                 If[s["note"] === "", "", Style[s["note"], Italic, Gray, Smaller]]}] /@ a["steps"],
    {relExprShow @@ a["start"], "", Style["(start)", Gray, Smaller]}],
  Alignment -> {{Left, Center, Left}, Baseline},
  Dividers -> {None, {2 -> GrayLevel[0.85]}}, Spacings -> {1.6, 0.75}];

TwoSided /: MakeBoxes[obj : TwoSided[a_Association], fmt : (StandardForm | TraditionalForm)] :=
  BoxForm`ArrangeSummaryBox[
    TwoSided, obj,
    Graphics[{Lookup[$statusColor, twoSidedOverall[obj]], Disk[]}, ImageSize -> {12, 12}],
    {BoxForm`SummaryItem[{"relation: ", relExprShow[a["lhs"], a["rel"], a["rhs"]]}],
     BoxForm`SummaryItem[{"status: ", Style[Lookup[$statusGlyph, twoSidedOverall[obj]],
        Lookup[$statusColor, twoSidedOverall[obj]], Bold]}]},
    {BoxForm`SummaryItem[{"steps:  ", Length[a["steps"]]}], twoSidedGrid[a]},
    fmt, "Interpretable" -> Automatic];

TwoSided /: Format[obj : TwoSided[a_Association], OutputForm] :=
  Row[{"TwoSided[ ", a["lhs"], " ", relationLabel[a["rel"]], " ", a["rhs"], "  ",
       Lookup[$statusGlyph, twoSidedOverall[obj]], " ]"}];
TwoSided /: Format[obj : TwoSided[a_Association], TextForm] := MakeBoxes[obj, OutputForm];
