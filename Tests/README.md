# Calculemus test suite

Hierarchical, continue-on-failure self-checks. **293 assertions** across 12 suites
(Core, Expr, Subexpr, Series, Matrix, Integral, Sums, Bounds, Inequalities,
TwoSided, Syntax, Gaussian).

## Running

`wolframscript` is not on PATH; the binary is inside the Mathematica app bundle:

```bash
WS="/Applications/Mathematica 2.app/Contents/MacOS/wolframscript"

"$WS" -file Tests/RunTests.wl          # everything, one combined report
"$WS" -file Tests/CoreTests.wl         # a single suite, standalone
```

Both exit `0` if all pass, `1` on any failure (CI-friendly). `RunTests.wl` loads
the kernel and every suite into one process and prints a tree grouped by
suite → section, listing only the failures.

## Layout

- `TestHarness.wl` — shared harness. Loads the kernel once, then defines:
  - `suite["..."]`, `section["..."]`, `subsection["..."]` — grouping
  - `test["label", condition]` — one assertion; `HoldRest`, so a failure prints
    the source condition. Never aborts the run.
  - helpers: `same`, `near`, `ncSame`, `statusOf[d, k]`, `lastStatus[d]`
  - `endSuite[]` (standalone report + exit), `reportAll[]` (used by the runner)
- `RunTests.wl` — the master runner.
- `<Module>Tests.wl` — one suite per source module.

## Adding a test

```mathematica
Get[FileNameJoin[{DirectoryName[$InputFileName], "TestHarness.wl"}]];
suite["MyModule"];
section["some behaviour";
test["does the thing", same[result[d], expected]];
endSuite[];
```

Conventions:
- Wrap steps that legitimately emit messages (Refuted, contradiction, …) in
  `Quiet` inside the condition: `test["bad step refuted", Quiet@step[...] ...]`.
- The Matrix/Gaussian suites declare non-commutative symbols, so they use unique
  `mt…` / `vc…` / `g…` names — never reuse those as scalars in another suite, or
  running everything in one kernel would mis-route the scalar expressions.
