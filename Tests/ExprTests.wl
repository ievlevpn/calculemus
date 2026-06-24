(* ::Package:: *)

(* Calculemus general expression-algebra self-checks (complete-the-square,
   abbreviations). Standalone:  wolframscript -file Tests/ExprTests.wl  *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "TestHarness.wl"}]];
suite["Expr"];

(* ============================================================ *)
section["complete the square (scalar)"];
dCS = derive[al x^2 + be x + ga] // step[completeSquare[x]];
test["completes & verifies", verifiedQ[dCS]];
test["leading coeff preserved", same[Coefficient[Expand[result[dCS]], x, 2], al]];
test["value preserved", same[Expand[result[dCS]], al x^2 + be x + ga]];
dCSnum = derive[2 x^2 + 4 x + 5] // step[completeSquare[x]];
test["numeric completion verified", verifiedQ[dCSnum]];
test["numeric completion value", same[Expand[result[dCSnum]], 2 x^2 + 4 x + 5]];
dCSbad = Quiet@step[derive[al x^2 + be x + ga], Function[cur, al (x + be/(2 al))^2]];
test["dropping the constant is Refuted", statusOf[dCSbad] === "Refuted"];

(* ============================================================ *)
section["abbreviation: name, work, restore"];
dAb = derive[(p + q)^2 + (p + q)] //
      step[abbreviate[s, p + q], "let s = p+q"] //
      step[rewrite[s^2 + s -> s (s + 1)], "factor"] //
      step[restore[s], "restore s"];
test["final result", same[result[dAb], (p + q) (p + q + 1)]];
test["chain verified", verifiedQ[dAb]];
test["definition recorded", definitionsOf[dAb] === {s -> p + q}];
test["middle step is written in s", ! FreeQ[stepsOf[dAb][[2]]["result"], s]];

(* ---- restoreAll expands every abbreviation ---- *)
dAll = derive[a^2 + b] //
       step[abbreviate[u, a^2]] // step[abbreviate[v, b]] // step[restoreAll];
test["restoreAll result", same[result[dAll], a^2 + b]];
test["restoreAll verified", verifiedQ[dAll]];
test["two definitions recorded", Length[definitionsOf[dAll]] === 2];

(* ---- verification expands abbreviations: a wrong step under a name is caught ---- *)
dAbBad = Quiet@step[derive[(p + q)^2] // step[abbreviate[s, p + q]], rewrite[s^2 -> s^3]];
test["wrong step under abbreviation Refuted", statusOf[dAbBad, 2] === "Refuted"];

(* ---- abbreviating an NC expression keeps the name non-commutative ---- *)
ncDeclare[exA, exB];
dNCab = derive[exA ** exB] // step[abbreviate[exP, exA ** exB]];
test["NC abbreviation verified", verifiedQ[dNCab]];
test["NC abbreviation name is non-commutative", Quiet[CommutativeQ[exP]] === False];

endSuite[];
