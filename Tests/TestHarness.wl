(* ::Package:: *)

(* Calculemus shared test harness — hierarchical, continue-on-failure.

   A test file uses it like:
       Get[FileNameJoin[{DirectoryName[$InputFileName], "TestHarness.wl"}]];
       suite["Core"];
       section["relations algebra"];
       test["<= o <=", composeRelation[LessEqual, LessEqual] === LessEqual];
       endSuite[];   (* standalone: prints this suite's report and exits 0/1 *)

   The harness loads the Calculemus kernel exactly once. Run the WHOLE suite with
       wolframscript -file Tests/RunTests.wl
   which sets $aggregating = True, gets every suite, and prints one combined tree.

   Design notes:
   - Top-level statements are evaluated in order by Get, so the kernel is loaded
     BEFORE the helper definitions are read — otherwise Calculemus` symbols used
     in the helpers (e.g. stepsOf) would intern into Global` and silently misfire.
   - test[label, cond] is HoldRest: on failure it shows the source condition.
   - Tests NEVER abort the run; a failed assertion is recorded and we continue.
   - Steps that legitimately emit messages (Refuted, contradiction, ...) should be
     wrapped in Quiet inside the condition: test["x", Quiet@step[...] ...]. *)

(* ---- 1. load the kernel once (own statement, so the path is set before defs) ---- *)
If[! TrueQ[$calculemusLoaded],
  Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "Calculemus.wl"}]];
  $calculemusLoaded = True];

(* ---- 2. state, initialised once (re-Get must NOT wipe accumulated records) ---- *)
If[! ValueQ[$testRecords],
  $testRecords = {}; $suiteName = "?"; $section = ""; $subsection = "";
  $aggregating = TrueQ[$aggregating]];

(* ---- 3. definitions (idempotent; read with Calculemus` already on the path) ---- *)
suite[n_]      := ($suiteName = n; $section = ""; $subsection = "";);
section[n_]    := ($section = n; $subsection = "";);
subsection[n_] := ($subsection = n;);

SetAttributes[test, HoldRest];
test[label_, cond_] := Module[{ok},
  ok = TrueQ[cond];
  AppendTo[$testRecords,
    <|"suite" -> $suiteName, "section" -> $section, "sub" -> $subsection,
      "label" -> label, "ok" -> ok, "cond" -> HoldForm[cond]|>];
  ok];

(* ---- equality / numeric helpers ---- *)
same[a_, b_]       := TrueQ[Simplify[a - b] === 0] || a === b;
near[a_, b_]       := TrueQ[Abs[N[a] - N[b]] <= 10.^-6 (1 + Abs[N[b]])];
ncSame[a_, b_]     := Quiet[NCExpand[a - b]] === 0;
statusOf[d_, k_:1] := stepsOf[d][[k]]["cert"]["status"];   (* k-th step status *)
lastStatus[d_]     := stepsOf[d][[-1]]["cert"]["status"];

(* ---- reporting ---- *)
doReport[recs_] := Module[{fails, total, npass, suites},
  total = Length[recs]; npass = Count[recs, r_ /; r["ok"]];
  fails = Select[recs, ! #["ok"] &];
  suites = DeleteDuplicates[#["suite"] & /@ recs];
  Print["\n==================== CALCULEMUS TEST REPORT ===================="];
  Do[Module[{sr = Select[recs, #["suite"] === su &]},
      Print["\n", su, "  (", Count[sr, r_ /; r["ok"]], "/", Length[sr], ")"];
      Do[Module[{cr = Select[sr, #["section"] === se &]},
         Print["   ", If[se === "", "(general)", se],
               "  (", Count[cr, r_ /; r["ok"]], "/", Length[cr], ")"];
         Do[Print["       FAIL  ", If[f["sub"] === "", "", f["sub"] <> " > "],
                  f["label"], "  ::  ", f["cond"]],
            {f, Select[cr, ! #["ok"] &]}]],
         {se, DeleteDuplicates[#["section"] & /@ sr]}]],
     {su, suites}];
  Print["\n---------------------------------------------------------------"];
  If[fails === {}, Print["ALL ", total, " TESTS PASSED"],
    Print[Length[fails], " FAILED of ", total, " (", npass, " passed)"]];
  Print["===============================================================\n"];
  Length[fails]];

(* standalone: report just-loaded records and exit. aggregate: defer to reportAll. *)
endSuite[]  := If[! TrueQ[$aggregating], If[doReport[$testRecords] > 0, Exit[1], Exit[0]]];
reportAll[] := If[doReport[$testRecords] > 0, Exit[1], Exit[0]];
