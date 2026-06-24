(* ::Package:: *)

(* Shared display helper for the examples. Load AFTER the FormalCalc package.
   Prints a derivation as a readable, verified chain. *)

showChain[title_, d_Derivation] := Module[{a = First[d]},
  Print[""]; Print["===== ", title, " ====="];
  Print["  start:  ", a["start"]];
  Scan[Function[s,
     Print["    ", relationLabel[s["relation"]], "  ", s["result"]];
     Print["         [", s["cert"]["status"], "]  ", s["note"]]],
   a["steps"]];
  Print["  ---"];
  Print["  overall:  (start) ", relationLabel[relationOf[d]],
        " (result)    all steps verified: ", verifiedQ[d]];
  Print[""];
];

showChain[title_, d_TwoSided] := Module[{a = First[d]},
  Print[""]; Print["===== ", title, " ====="];
  Print["  start:  ", a["start"][[1]], " ", relationLabel[a["start"][[2]]], " ", a["start"][[3]]];
  Scan[Function[s,
     Print["    ", s["lhs"], " ", relationLabel[s["rel"]], " ", s["rhs"]];
     Print["         [", s["cert"]["status"], "]  ", s["note"]]],
   a["steps"]];
  Print["  ---"];
  Print["  overall verified: ", verifiedQ[d]];
  Print[""];
];
