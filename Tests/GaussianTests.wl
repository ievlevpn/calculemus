(* ::Package:: *)

(* Calculemus`Gaussian` DOMAIN-PACK self-checks. Loads the general core, then the
   separate Gaussian context on top.
     wolframscript -file Tests/GaussianTests.wl  *)

dir = DirectoryName[$InputFileName];
Get[FileNameJoin[{dir, "..", "Kernel", "Calculemus.wl"}]];
Get[FileNameJoin[{dir, "..", "Source", "Domain", "Gaussian.wl"}]];

ClearAll[assert];
SetAttributes[assert, HoldFirst];
assert[cond_, label_: ""] := If[TrueQ[cond], $passed++,
  Print["FAILED: ", label, " :: ", HoldForm[cond]]; Exit[1]];
$passed = 0;

(* the domain symbols live in their own context, NOT in the core *)
assert[Context[gaussExp] === "Calculemus`Gaussian`", "gaussExp is in the domain context"];

ncDeclareSym[cov]; ncDeclareVec[xx, yy];

(* gaussExp builds the log-density exponent; prefactorExponent is the ratio's exponent *)
assert[gaussExp[xx, cov] === -(1/2) tp[xx] ** inv[cov] ** xx, "gaussExp constructor"];
assert[prefactorExponent[xx, cov, yy, cov] === gaussExp[xx, cov] - gaussExp[yy, cov],
   "prefactorExponent constructor"];

(* the domain object flows through the general verified machinery: the two log-density
   exponents at x and -x are equal (centered density is even), verified on random data *)
dEven = derive[gaussExp[xx, cov]] // step[# /. xx -> -xx &];
assert[verifiedQ[dEven], "gaussExp(-x) = gaussExp(x) verified by core machinery"];

Print["ALL TESTS PASSED (", $passed, " assertions)"];
