(* ::Package:: *)

(* FormalCalc Core (Layer 0 + Layer 2): relations algebra, verification,
   the Derivation relation-chain, and rewrite helpers.
   Loaded by Kernel/FormalCalc.wl inside FormalCalc`Private`. *)

(* ============================================================ *)
(* Relations algebra                                            *)
(* ============================================================ *)

$relationLabels = <|
  Equal -> "=", LessEqual -> "\[LessEqual]", GreaterEqual -> "\[GreaterEqual]",
  Less -> "<", Greater -> ">", AsymEqual -> "~"
|>;
relationLabel[r_] := Lookup[$relationLabels, r, ToString[r]];

flipRelation[Equal]        = Equal;
flipRelation[LessEqual]    = GreaterEqual;
flipRelation[GreaterEqual] = LessEqual;
flipRelation[Less]         = Greater;
flipRelation[Greater]      = Less;
flipRelation[AsymEqual]    = AsymEqual;

composeRelation::incomp = "Cannot compose incomparable relations `1` and `2`.";
composeRelation[Equal, r_]              := r;
composeRelation[r_, Equal]              := r;
composeRelation[AsymEqual, AsymEqual]   := AsymEqual;
composeRelation[LessEqual, LessEqual]   := LessEqual;
composeRelation[LessEqual, Less]        := Less;
composeRelation[Less, LessEqual]        := Less;
composeRelation[Less, Less]             := Less;
composeRelation[GreaterEqual, GreaterEqual] := GreaterEqual;
composeRelation[GreaterEqual, Greater]  := Greater;
composeRelation[Greater, GreaterEqual]  := Greater;
composeRelation[Greater, Greater]       := Greater;
composeRelation[a_, b_]                 := (Message[composeRelation::incomp, a, b]; $Failed);

(* ============================================================ *)
(* Verification (§0.4)                                          *)
(* ============================================================ *)

relationExpr[Equal, b_, a_]        := b == a;
relationExpr[LessEqual, b_, a_]    := b <= a;
relationExpr[GreaterEqual, b_, a_] := b >= a;
relationExpr[Less, b_, a_]         := b < a;
relationExpr[Greater, b_, a_]      := b > a;

(* --- symbolic check --- *)
symbolicVerdict[before_, after_, AsymEqual, asm_] := Unknown;
symbolicVerdict[before_, after_, rel_, asm_] := Module[{s},
  s = Simplify[relationExpr[rel, before, after], asm];
  Which[
    s === True, True,
    s === False, False,
    rel === Equal && TrueQ[Quiet@PossibleZeroQ[before - after]], True,
    True, Unknown
  ]
];

(* --- numeric probe --- *)
freeSymbols[exprs_] := DeleteDuplicates@Cases[
  exprs, s_Symbol /; (Context[s] =!= "System`" && ! NumericQ[s]),
  {0, Infinity}, Heads -> False
];

trivialAsmQ[asm_] := asm === True || asm === {} || asm === None;

samplePoints[{}, asm_, n_] := {{}};
samplePoints[vars_, asm_, n_] := Module[{seed, pts},
  seed = If[trivialAsmQ[asm],
    Thread[vars -> RandomReal[{0.2, 3.0}, Length[vars]]],
    Quiet@Check[
      Module[{fi = FindInstance[asm, vars, Reals]},
        If[Head[fi] =!= List || fi === {}, $Failed,
           Thread[vars -> (vars /. First[fi])]]],
      $Failed]
  ];
  If[seed === $Failed, Return[$Failed]];
  pts = Table[
    Thread[vars -> ((vars /. seed) RandomReal[{0.6, 1.6}, Length[vars]]
                    + RandomReal[{-0.05, 0.05}, Length[vars]])],
    {n}];
  pts = Select[pts, (trivialAsmQ[asm] || TrueQ[asm /. #]) &];
  If[pts === {}, {seed}, pts]
];

numericRelHolds[rel_, b_, a_, tol_] := Module[{bn = N[b], an = N[a], scale},
  If[! (NumericQ[bn] && NumericQ[an]), Return[Indeterminate]];
  scale = tol (1 + Abs[bn]);
  Switch[rel,
    Equal,        Abs[an - bn] <= scale,
    LessEqual,    bn - an <= scale,
    Less,         bn - an <= scale,
    GreaterEqual, an - bn <= scale,
    Greater,      an - bn <= scale,
    _,            Indeterminate]
];

numericVerdict[before_, after_, AsymEqual, asm_] := <|"verdict" -> Unknown, "trials" -> 0, "passed" -> 0|>;
numericVerdict[before_, after_, rel_, asm_] := Module[
  {vars, pts, res, tol = 10.^-8},
  vars = freeSymbols[{before, after, asm}];
  pts = samplePoints[vars, asm, 12];
  If[pts === $Failed, Return[<|"verdict" -> Unknown, "trials" -> 0, "passed" -> 0|>]];
  res = DeleteCases[
    Quiet@Map[numericRelHolds[rel, before /. #, after /. #, tol] &, pts],
    Indeterminate];
  Which[
    res === {},          <|"verdict" -> Unknown, "trials" -> 0, "passed" -> 0|>,
    MemberQ[res, False], <|"verdict" -> False, "trials" -> Length[res], "passed" -> Count[res, True]|>,
    True,                <|"verdict" -> True,  "trials" -> Length[res], "passed" -> Length[res]|>
  ]
];

$noNumeric = <|"verdict" -> Unknown, "trials" -> 0, "passed" -> 0|>;

(* defaults overridden by Matrix.wl / Integral.wl / Sums.wl when they load. *)
ncExprQ[_]  := False;
intExprQ[_] := False;
sumExprQ[_] := False;

certify[before_, after_, rel_, asm_] := certify[before, after, rel, asm, None, None, {}];

(* graded asymptotic equivalence: before ~ after iff their difference vanishes
   to the given order in the grading (§4.3). Verified via seriesExpand. *)
certify[before_, after_, AsymEqual, asm_, grading_, order_, relations_: {}] := Module[{rem, v},
  If[ncExprQ[{before, after}], Return[ncAsymCertify[before, after, asm, grading, order]]];
  If[grading === None || order === None,
    Return[<|"relation" -> AsymEqual, "symbolic" -> Unknown,
             "numeric" -> $noNumeric, "status" -> "Unverified"|>]];
  rem = seriesExpand[before - after, grading, order, asm];
  v = TrueQ[Simplify[rem == 0, asm]];
  <|"relation" -> AsymEqual, "symbolic" -> v, "numeric" -> $noNumeric,
    "status" -> If[v, "Verified", "Refuted"]|>
];

certify[before_, after_, rel_, asm_, grading_, order_, relations_: {}] := Module[{sym, num, status},
  If[ncExprQ[{before, after}], Return[ncCertify[before, after, rel, asm, relations]]];
  If[intExprQ[{before, after}], Return[intCertify[before, after, rel, asm]]];
  If[sumExprQ[{before, after}], Return[sumCertify[before, after, rel, asm]]];
  sym = symbolicVerdict[before, after, rel, asm];
  num = numericVerdict[before, after, rel, asm];
  status = Which[
    sym === False || num["verdict"] === False, "Refuted",
    sym === True,            "Verified",
    TrueQ[num["verdict"]],   "NumericOnly",
    True,                    "Unverified"
  ];
  <|"relation" -> rel, "symbolic" -> sym, "numeric" -> num, "status" -> status|>
];

(* ============================================================ *)
(* Rewrite helpers (§0.1)                                       *)
(* ============================================================ *)

at[expr_, pos : {__Integer}, f_]      := MapAt[f, expr, {pos}];
at[expr_, pos : {{___Integer} ..}, f_] := MapAt[f, expr, pos];
at[expr_, patt_, f_]                  := MapAt[f, expr, Position[expr, patt]];

rewrite[rule_] := Function[cur, cur /. rule];

(* ============================================================ *)
(* Derivation: the relation-chain (Layer 2)                     *)
(* ============================================================ *)

normalizeAsm[True]   := True;
normalizeAsm[a_List] := And @@ a;
normalizeAsm[a_]     := a;

Options[derive] = {Assumptions -> True, Grading -> None, GradingOrder -> None, Relations -> {}};
derive[expr_, OptionsPattern[]] := Derivation[<|
  "start" -> expr,
  "assumptions" -> normalizeAsm[OptionValue[Assumptions]],
  "grading" -> OptionValue[Grading],
  "order" -> OptionValue[GradingOrder],
  "relations" -> OptionValue[Relations],
  "steps" -> {}
|>];

result[Derivation[a_]]        := If[a["steps"] === {}, a["start"], Last[a["steps"]]["result"]];
assumptionsOf[Derivation[a_]] := a["assumptions"];
stepsOf[Derivation[a_]]       := a["steps"];
relationOf[Derivation[a_]]    := Fold[composeRelation, Equal, #["relation"] & /@ a["steps"]];
verifiedQ[Derivation[a_]]     := AllTrue[a["steps"], MemberQ[{"Verified", "NumericOnly"}, #["cert"]["status"]] &];

normalizeYield[Yields[e_, r_, note_]] := {e, r, note};
normalizeYield[Yields[e_, r_]]        := {e, r, ""};
normalizeYield[e_]                    := {e, Equal, ""};

step::refuted = "Step `1` failed verification (status: Refuted). Recorded anyway.";

stepCore[d : Derivation[a_], f_, noteOpt_] := Module[
  {cur = result[d], asm = assumptionsOf[d], new, rel, ynote, note, cert, rec,
   grading = Lookup[a, "grading", None], order = Lookup[a, "order", None],
   relations = Lookup[a, "relations", {}]},
  {new, rel, ynote} = normalizeYield[f[cur]];
  note = If[noteOpt === Automatic, ynote, noteOpt];
  cert = certify[cur, new, rel, asm, grading, order, relations];
  If[cert["status"] === "Refuted", Message[step::refuted, Length[a["steps"]] + 1]];
  rec = <|"result" -> new, "relation" -> rel, "note" -> note, "cert" -> cert|>;
  Derivation[<|a, "steps" -> Append[a["steps"], rec]|>]
];

step[d_Derivation, f_]               := stepCore[d, f, Automatic];
step[d_Derivation, f_, note_String]  := stepCore[d, f, note];
step[f_] /; Head[f] =!= Derivation              := Function[d, step[d, f]];
step[f_, note_String] /; Head[f] =!= Derivation := Function[d, step[d, f, note]];

(* ---- notebook rendering (display only; data via accessors) ---- *)
statusMark["Verified"]    := "\[Checkmark]";
statusMark["NumericOnly"] := "\[Checkmark]?";
statusMark["Refuted"]     := "\[Times]";
statusMark[_]             := "?";

Derivation /: MakeBoxes[Derivation[a_Association], fmt : (StandardForm | TraditionalForm)] :=
  Module[{rows},
    rows = Function[s, {relationLabel[s["relation"]], s["result"],
                        statusMark[s["cert"]["status"]], s["note"]}] /@ a["steps"];
    ToBoxes[
      Framed@Grid[Prepend[rows, {"", a["start"], "", ""}],
        Alignment -> {Left, Center}, Spacings -> {2, 1}],
      fmt]
  ];
