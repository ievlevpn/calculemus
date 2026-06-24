(* ::Package:: *)

(* FormalCalc Inequalities (Layer 1, §9.5): an extensible registry of standard
   inequalities applied as directional rewrites, each carrying side-conditions
   that are accumulated into the derivation's assumptions (and checked for
   contradiction). Users register their own (taken as given -> status Asserted).
   General inequalities only; domain ones (Markov, Slepian, ...) belong in packs.
   Loaded in FormalCalc`Private`. *)

$inequalities = <||>;

(* registerInequality[name, applyFn, relation, condFn, opts]
     applyFn : args -> (lhs -> rhs)  rewrite rule for those args
     condFn  : args -> {conditions}  side-assumptions for those args
   Options: "Assumed" -> True marks it as taken-as-given (status Asserted);
            "Description" -> "...". *)
Options[registerInequality] = {"Assumed" -> False, "Description" -> ""};
registerInequality[name_String, apply_, rel_, condFn_, OptionsPattern[]] :=
  ($inequalities[name] = <|"apply" -> apply, "relation" -> rel, "conditions" -> condFn,
     "assumed" -> OptionValue["Assumed"], "doc" -> OptionValue["Description"]|>; name);

(* user-defined inequality, taken as given *)
defineInequality[name_String, apply_, rel_, condFn_, opts : OptionsPattern[]] :=
  registerInequality[name, apply, rel, condFn, "Assumed" -> True, opts];

(* discover what is available *)
inequalities[] := Grid[
  Prepend[
    KeyValueMap[{#1, relationLabel[#2["relation"]], #2["doc"],
                 If[#2["assumed"], "assumed", ""]} &, $inequalities],
    Style[#, Bold] & /@ {"name", "rel", "description", ""}],
  Alignment -> Left, Dividers -> {None, {2 -> GrayLevel[0.8]}}, Spacings -> {2, 0.6}];

(* useIneq[name, {args...}] : the transform applying inequality `name` to `args`.
   It rewrites the matching subterm, asserts the inequality's relation, and emits
   the side-conditions for accumulation. The overall direction is verified by the
   core (a wrong-direction application is Refuted). *)
useIneq::unknown = "No inequality named `1` is registered.";
useIneq[name_String, args_List] := Function[cur,
  If[MissingQ[$inequalities[name]],
    (Message[useIneq::unknown, name]; cur),
    With[{spec = $inequalities[name]},
      Yields[cur /. (spec["apply"] @@ args), spec["relation"], "by " <> name,
        <|"conditions" -> normalizeAsm[spec["conditions"] @@ args],
          "assumed" -> spec["assumed"]|>]]]];
useIneq[name_String] := useIneq[name, {}];

(* assume[lhs -> rhs, relation, conditions] : an ad-hoc assumed bound (not
   registered), taken as given -> status Asserted, with conditions accumulated. *)
assume[rule_Rule, rel_ : LessEqual, conds_ : True] := Function[cur,
  Yields[cur /. rule, rel, "assumed", <|"conditions" -> normalizeAsm[conds], "assumed" -> True|>]];

(* ============================================================ *)
(* Standard general inequalities                                *)
(* ============================================================ *)
registerInequality["triangle", Function[{a, b}, Abs[a + b] -> Abs[a] + Abs[b]],
  LessEqual, (True &), "Description" -> "|a + b| <= |a| + |b|"];

registerInequality["amgm", Function[{a, b}, Sqrt[a b] -> (a + b)/2],
  LessEqual, Function[{a, b}, {a >= 0, b >= 0}], "Description" -> "Sqrt[a b] <= (a + b)/2"];

registerInequality["young", Function[{a, b, p, q}, a b -> a^p/p + b^q/q],
  LessEqual, Function[{a, b, p, q}, {a >= 0, b >= 0, p > 1, q > 1, 1/p + 1/q == 1}],
  "Description" -> "a b <= a^p/p + b^q/q  (Young)"];

registerInequality["exp-lower", Function[{x}, 1 + x -> Exp[x]],
  LessEqual, (True &), "Description" -> "1 + x <= e^x"];

registerInequality["log-upper", Function[{x}, Log[1 + x] -> x],
  LessEqual, Function[{x}, {x > -1}], "Description" -> "log(1 + x) <= x"];

registerInequality["bernoulli", Function[{x, r}, (1 + x)^r -> 1 + r x],
  GreaterEqual, Function[{x, r}, {x >= -1, r >= 1}], "Description" -> "(1 + x)^r >= 1 + r x"];
