(* ::Package:: *)

(* Calculemus master test runner — loads the kernel once and every suite into a
   single kernel, then prints one combined hierarchical report.
     wolframscript -file Tests/RunTests.wl
   Exits 0 if all suites pass, 1 otherwise.

   Suite order matters: the Matrix/Gaussian suites declare non-commutative
   symbols, so they use unique mt / vc / g prefixed names no scalar suite reuses. *)

$aggregating = True;
$dir = DirectoryName[$InputFileName];
Get[FileNameJoin[{$dir, "TestHarness.wl"}]];

$suites = {
  "CoreTests.wl", "ExprTests.wl", "SubexprTests.wl", "SeriesTests.wl",
  "MatrixTests.wl", "IntegralTests.wl", "SumsTests.wl", "BoundsTests.wl",
  "InequalitiesTests.wl", "TwoSidedTests.wl", "SyntaxTests.wl", "GaussianTests.wl"};

Get[FileNameJoin[{$dir, #}]] & /@ $suites;

reportAll[];
