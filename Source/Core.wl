(* ::Package:: *)

(* Calculemus Core (Layer 0 + Layer 2): relations algebra, verification,
   the Derivation relation-chain, and rewrite helpers.
   Loaded by Kernel/Calculemus.wl inside Calculemus`Private`. *)

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
  (* unconstrained variables are sampled with BOTH signs (plus one all-positive
     point for expressions only defined there), so a sign-dependent claim like
     Sqrt[x^2] == x cannot pass on a positive-only probe *)
  If[trivialAsmQ[asm],
    Return[Prepend[
      Table[Thread[vars -> RandomChoice[{-1, 1}, Length[vars]] RandomReal[{0.2, 3.0}, Length[vars]]], {n}],
      Thread[vars -> RandomReal[{0.2, 3.0}, Length[vars]]]]]];
  seed = Quiet@Check[
    Module[{fi = FindInstance[asm, vars, Reals]},
      If[Head[fi] =!= List || fi === {}, $Failed,
         Thread[vars -> (vars /. First[fi])]]],
    $Failed];
  If[seed === $Failed, Return[$Failed]];
  pts = Table[
    Thread[vars -> ((vars /. seed) RandomReal[{0.6, 1.6}, Length[vars]]
                    + RandomReal[{-0.05, 0.05}, Length[vars]])],
    {n}];
  pts = Select[pts, TrueQ[asm /. #] &];
  If[pts === {}, {seed}, pts]
];

numericRelHolds[rel_, b_, a_, tol_] := Module[{bn = N[b], an = N[a], scale, r},
  If[! (NumericQ[bn] && NumericQ[an]), Return[Indeterminate]];
  scale = tol (1 + Abs[bn]);
  r = Switch[rel,
    Equal,        Abs[an - bn] <= scale,
    LessEqual,    bn - an <= scale,
    Less,         bn - an <= scale,
    GreaterEqual, an - bn <= scale,
    Greater,      an - bn <= scale,
    _,            Indeterminate];
  (* complex probe values leave order comparisons unevaluated: no data, not a pass *)
  If[r === True || r === False, r, Indeterminate]
];

numericVerdict[before_, after_, AsymEqual, asm_] := <|"verdict" -> Unknown, "trials" -> 0, "passed" -> 0|>;
numericVerdict[before_, after_, rel_, asm_] := Module[
  {vars, pts, evals, res, bad, tol = 10.^-8},
  vars = freeSymbols[{before, after, asm}];
  pts = samplePoints[vars, asm, 12];
  If[pts === $Failed, Return[<|"verdict" -> Unknown, "trials" -> 0, "passed" -> 0|>]];
  evals = DeleteCases[
    Quiet@Map[{#, numericRelHolds[rel, before /. #, after /. #, tol]} &, pts],
    {_, Indeterminate}];
  res = evals[[All, 2]];
  Which[
    res === {},          <|"verdict" -> Unknown, "trials" -> 0, "passed" -> 0|>,
    MemberQ[res, False],
      bad = FirstCase[evals, {pt_, False} :> pt];
      <|"verdict" -> False, "trials" -> Length[res], "passed" -> Count[res, True],
        "witness" -> <|"point" -> bad, "before" -> Quiet@N[before /. bad], "after" -> Quiet@N[after /. bad]|>|>,
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
  "defs" -> {},
  "steps" -> {}
|>];

result[Derivation[a_]]        := If[a["steps"] === {}, a["start"], Last[a["steps"]]["result"]];
assumptionsOf[Derivation[a_]] := a["assumptions"];
definitionsOf[Derivation[a_]] := Lookup[a, "defs", {}];
stepsOf[Derivation[a_]]       := a["steps"];
relationOf[Derivation[a_]]    := Fold[composeRelation, Equal, #["relation"] & /@ a["steps"]];
verifiedQ[Derivation[a_]]     := AllTrue[a["steps"], MemberQ[{"Verified", "NumericOnly", "Asserted"}, #["cert"]["status"]] &];

(* a transform returns a bare expression (equality), or Yields[expr, relation, note,
   meta], where meta may carry "conditions" (side-assumptions to accumulate) and
   "assumed" -> True (taken as given -> status Asserted). *)
normalizeYield[Yields[e_, r_, note_, meta_Association]] := {e, r, note, meta};
normalizeYield[Yields[e_, r_, note_]] := {e, r, note, <||>};
normalizeYield[Yields[e_, r_]]        := {e, r, "", <||>};
normalizeYield[e_]                    := {e, Equal, "", <||>};

(* conjoin assumptions, flattening And and dropping True *)
conjoinAsm[a_, b_] := With[
  {parts = DeleteCases[DeleteDuplicates@Flatten[{a, b} /. And -> List], True]},
  Which[parts === {}, True, Length[parts] == 1, First[parts], True, And @@ parts]];

(* an "obvious contradiction": provably unsatisfiable over the reals *)
contradictoryQ[True] := False;
contradictoryQ[asm_] := TrueQ@Quiet@TimeConstrained[Reduce[asm, Reals] === False, 3, False];

step::refuted = "Step `1` failed verification (status: Refuted).`2` Recorded anyway.";
step::noop = "The transform left the expression unchanged (a rewrite whose left side matched nothing?); no step recorded.";
step::contradiction = "Step `1` introduces assumptions `2` that contradict those already in force; rejected.";

(* the numeric counterexample, if the probe found one, as message text *)
witnessText[cert_] := With[{w = Lookup[Lookup[cert, "numeric", <||>], "witness", None]},
  If[! AssociationQ[w], "",
    " Counterexample at " <> ToString[w["point"], InputForm] <>
    ": before = " <> ToString[w["before"], InputForm] <>
    ", after = " <> ToString[w["after"], InputForm] <> "."]];

stepCore[d : Derivation[a_], f_, noteOpt_] := Module[
  {cur = result[d], asm = assumptionsOf[d], new, rel, ynote, meta, note, cert, rec,
   grading = Lookup[a, "grading", None], order = Lookup[a, "order", None],
   relations = Lookup[a, "relations", {}], defs = Lookup[a, "defs", {}],
   conds, assumed, newAsm, defn, newDefs, n = Length[a["steps"]] + 1},
  (* a transform may be a plain expr->result function, or WithContext[(expr,ctx)->result]
     to read Grading/GradingOrder/Relations/Assumptions/Defs set once on the derivation. *)
  {new, rel, ynote, meta} = normalizeYield[
    If[Head[f] === WithContext,
      First[f][cur, <|"grading" -> grading, "order" -> order, "relations" -> relations,
                      "assumptions" -> asm, "defs" -> defs|>],
      f[cur]]];
  note = If[noteOpt === Automatic, ynote, noteOpt];
  (* honesty guard: a transform that did nothing (and introduced nothing) must
     not add a verified-looking line to the chain *)
  If[new === cur && rel === Equal && Lookup[meta, "conditions", True] === True &&
     Lookup[meta, "define", Nothing] === Nothing && ! TrueQ[Lookup[meta, "assumed", False]],
    Message[step::noop]; Return[d]];
  conds = normalizeAsm[Lookup[meta, "conditions", True]];
  assumed = TrueQ@Lookup[meta, "assumed", False];
  newAsm = conjoinAsm[asm, conds];
  defn = Lookup[meta, "define", Nothing];          (* abbreviation w -> expr, if any *)
  newDefs = If[defn === Nothing, defs, Append[defs, defn]];
  (* accumulate side-assumptions; reject on an obvious contradiction *)
  If[conds =!= True && contradictoryQ[newAsm],
    Message[step::contradiction, n, conds];
    cert = <|"relation" -> rel, "symbolic" -> False, "numeric" -> $noNumeric, "status" -> "Refuted"|>;
    rec = <|"result" -> new, "relation" -> rel, "note" -> note <> " [contradictory assumptions]", "cert" -> cert|>;
    Return[Derivation[<|a, "steps" -> Append[a["steps"], rec]|>]]];
  (* verify on the DEFINITION-EXPANDED expressions, so abbreviations are transparent *)
  cert = certify[cur //. newDefs, new //. newDefs, rel, newAsm, grading, order, relations];
  If[assumed, cert = <|cert, "status" -> "Asserted"|>];   (* taken as given *)
  If[cert["status"] === "Refuted", Message[step::refuted, n, witnessText[cert]]];
  rec = <|"result" -> new, "relation" -> rel, "note" -> note, "cert" -> cert|>;
  Derivation[<|a, "assumptions" -> newAsm, "defs" -> newDefs, "steps" -> Append[a["steps"], rec]|>]
];

step[d_Derivation, f_]               := stepCore[d, f, Automatic];
step[d_Derivation, f_, note_String]  := stepCore[d, f, note];
step[f_] /; Head[f] =!= Derivation              := Function[d, step[d, f]];
step[f_, note_String] /; Head[f] =!= Derivation := Function[d, step[d, f, note]];

(* ============================================================ *)
(* Display (notebook + terminal). Data is always via accessors. *)
(* ============================================================ *)

$statusColor = <|"Verified" -> Darker[Green, 0.2], "NumericOnly" -> RGBColor[0., 0.55, 0.5],
                 "Asserted" -> RGBColor[0.5, 0.33, 0.7],
                 "Refuted" -> Red, "Unverified" -> Gray|>;
$statusGlyph = <|"Verified" -> "\[Checkmark]", "NumericOnly" -> "\[Checkmark]",
                 "Asserted" -> "\[RightTee]", "Refuted" -> "\[Times]", "Unverified" -> "?"|>;
$statusTip   = <|"Verified" -> "verified symbolically", "NumericOnly" -> "verified numerically (probe)",
                 "Asserted" -> "asserted \[Dash] taken as given (by hypothesis)",
                 "Refuted" -> "REFUTED \[Dash] the asserted relation does not hold",
                 "Unverified" -> "not verified"|>;

statusBadge[st_] := Tooltip[
  Style[Lookup[$statusGlyph, st, "?"], Lookup[$statusColor, st, Gray], Bold],
  Lookup[$statusTip, st, st]];

overallStatus[d_] := Which[
  AnyTrue[stepsOf[d], #["cert"]["status"] === "Refuted" &], "Refuted",
  AnyTrue[stepsOf[d], #["cert"]["status"] === "Asserted" &] && verifiedQ[d], "Asserted",
  verifiedQ[d], "Verified", True, "Unverified"];

verifiedSummary[d_] := With[{st = overallStatus[d]},
  Style[Row[{Lookup[$statusGlyph, st], " ",
             Switch[st, "Refuted", "refuted step", "Verified", "all steps verified",
                        "Asserted", "verified, uses assumed step(s)", _, "unverified step(s)"]}],
        Lookup[$statusColor, st], Bold]];

(* ---- caveats: the steps the result RESTS ON without proof (Asserted/Unverified) ---- *)
caveatSteps[d_] := Select[stepsOf[d], MemberQ[{"Asserted", "Unverified"}, #["cert"]["status"]] &];

caveatLine[s_] := If[KeyExistsQ[s, "result"],
  Row[{relationLabel[s["relation"]], "  ", s["result"]}],
  Row[{s["lhs"], "  ", relationLabel[s["rel"]], "  ", s["rhs"]}]];

caveats[d : (_Derivation | _TwoSided)] := Module[{rows},
  rows = Cases[MapIndexed[{First[#2], #1} &, stepsOf[d]],
    {i_, s_} /; MemberQ[{"Asserted", "Unverified"}, s["cert"]["status"]] :>
      {i, statusBadge[s["cert"]["status"]], caveatLine[s],
       If[s["note"] === "", "", Style[s["note"], Italic, Gray]]}];
  If[rows === {}, Style["(no unverified claims \[Dash] fully verified)", Gray, Italic],
    Framed@Column[{
      Style["This result rests on the following unverified claim(s):", Bold],
      Grid[Prepend[rows, Style[#, Bold, Gray] & /@ {"#", "", "claim", "note"}],
        Alignment -> {{Right, Center, Left, Left}, Baseline}, Spacings -> {2, 0.6},
        Dividers -> {None, {2 -> GrayLevel[0.8]}}]},
     FrameStyle -> Lookup[$statusColor, "Asserted"]]]];

(* the full annotated proof chain *)
chainGrid[a_] := Module[{steps = a["steps"], rows},
  rows = MapIndexed[Function[{s, i},
     {Style[First[i], Gray, Tiny],
      Style[relationLabel[s["relation"]], Bold, GrayLevel[0.45]],
      Row[{"  ", s["result"]}],
      statusBadge[s["cert"]["status"]],
      If[s["note"] === "", "", Style[s["note"], Italic, Gray, Smaller]]}],
    steps];
  Grid[
    Prepend[rows, {"", "", Row[{"  ", a["start"]}], "", Style["(start)", Gray, Smaller]}],
    Alignment -> {{Right, Center, Left, Center, Left}, Baseline},
    Dividers -> {None, {2 -> GrayLevel[0.85]}},
    Spacings -> {1.3, 0.75}]];

derivIcon[d_] := Graphics[
  {Lookup[$statusColor, overallStatus[d]], Disk[]},
  ImageSize -> {12, 12}, Background -> None];

Derivation /: MakeBoxes[d : Derivation[a_Association], fmt : (StandardForm | TraditionalForm)] :=
  BoxForm`ArrangeSummaryBox[
    Derivation, d, derivIcon[d],
    (* collapsed: the essentials *)
    Join[
      {BoxForm`SummaryItem[{"result: ", Row[{a["start"], " ",
          Style[relationLabel[relationOf[d]], Bold, GrayLevel[0.45]], " ", result[d]}]}],
       BoxForm`SummaryItem[{"status: ", verifiedSummary[d]}]},
      If[caveatSteps[d] === {}, {},
        {BoxForm`SummaryItem[{"rests on: ", Style[Row[{Length[caveatSteps[d]],
           " unverified claim(s)"}], Lookup[$statusColor, "Asserted"], Bold]}]}]],
    (* expanded: the full chain + accumulated assumptions *)
    Join[
      {BoxForm`SummaryItem[{"steps:  ", Length[a["steps"]]}]},
      If[assumptionsOf[d] === True, {},
         {BoxForm`SummaryItem[{"assumptions:  ", assumptionsOf[d]}]}],
      {chainGrid[a]}],
    fmt, "Interpretable" -> Automatic];

(* terminal / OutputForm fallback: a clean one-liner (Print uses Format) *)
derivLine[d_Derivation] := With[{a = First[d]},
  Row[{"Derivation[", Length[a["steps"]], " step(s): ", a["start"], " ",
       relationLabel[relationOf[d]], " ", result[d], "  ",
       Lookup[$statusGlyph, overallStatus[d]], "]"}]];
Derivation /: Format[d_Derivation, OutputForm] := derivLine[d];
Derivation /: Format[d_Derivation, TextForm]   := derivLine[d];
