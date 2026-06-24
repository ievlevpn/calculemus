(* ::Package:: *)

(* Calculemus`Gaussian` DOMAIN-PACK self-checks. Loads the general core (via the
   harness), then the separate Gaussian context on top.
   Standalone:  wolframscript -file Tests/GaussianTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "TestHarness.wl"}]];
If[! TrueQ[$gaussianLoaded],
  Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Source", "Domain", "Gaussian.wl"}]];
  $gaussianLoaded = True];
suite["Gaussian"];

ncDeclareSym[gcov]; ncDeclareVec[gvx, gvy];

(* ============================================================ *)
section["context separation"];
test["gaussExp lives in the domain context", Context[gaussExp] === "Calculemus`Gaussian`"];

(* ============================================================ *)
section["constructors"];
test["gaussExp log-density exponent",
  gaussExp[gvx, gcov] === -(1/2) tp[gvx] ** inv[gcov] ** gvx];
test["prefactorExponent is the ratio's exponent",
  prefactorExponent[gvx, gcov, gvy, gcov] === gaussExp[gvx, gcov] - gaussExp[gvy, gcov]];

(* ============================================================ *)
section["flows through the general verified machinery"];
(* centered density is even: gaussExp(-x) = gaussExp(x), verified on random data *)
dEven = derive[gaussExp[gvx, gcov]] // step[# /. gvx -> -gvx &];
test["gaussExp(-x) = gaussExp(x) verified", verifiedQ[dEven]];

endSuite[];
