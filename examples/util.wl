(* ::Package:: *)

(* Shared display helper for the examples. Load AFTER the FormalCalc package.
   Prints a derivation as a readable, verified chain. *)

showChain[title_, d_] := Module[{a = First[d]},
  Print[""];
  Print["===== ", title, " ====="];
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
