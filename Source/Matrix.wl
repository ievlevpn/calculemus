(* ::Package:: *)

(* FormalCalc Matrix (Layer 1, §3 + §4.6): non-commutative / matrix algebra.
   Thin layer over NCAlgebra (tp/aj/inv/** used directly) that adds what
   NCAlgebra lacks: a graded NC Neumann inverse, integration into the
   Derivation chain, and RANDOM-MATRIX verification wired into certify.

   NCAlgebra makes single lowercase letters non-commutative by default, which
   clashes with ordinary scalar variable names, so we DO NOT use CommutativeQ
   to route work. NC status is tracked explicitly via ncDeclare. Ordinary
   Times/Plus/Simplify on those symbols still behave commutatively, so the
   scalar modules are unaffected. Loaded inside FormalCalc`Private`. *)

$ncSyms = {};

SetAttributes[ncDeclare, HoldAll];
ncDeclare[syms__] := (SetNonCommutative[syms]; $ncSyms = Union[$ncSyms, {syms}];);

(* an expression is "NC" if it uses **/tp/aj/inv or a declared NC symbol *)
ncExprQ[e_] := ! FreeQ[e, NonCommutativeMultiply | tp | aj | inv] ||
               IntersectingQ[Cases[e, _Symbol, {0, Infinity}], $ncSyms];

(* symbols to randomize: declared NC, or NCAlgebra-non-commutative *)
ncSymbolsIn[e_] := Select[DeleteDuplicates@Cases[e, _Symbol, {0, Infinity}],
  (MemberQ[$ncSyms, #] || TrueQ[Quiet[CommutativeQ[#]] === False]) &];

(* ---- map an NC expression to concrete numeric matrices ---- *)
toNum[expr_, dim_] := Module[{r},
  (* NCAlgebra writes mA**mA as mA^2 and inv[mA] as mA^(-1) (both Power), and
     re-collapses any ** we make. Map every nonzero-integer NC power straight to
     MatrixPower (so mA^(-1) -> matrix inverse, not element-wise reciprocal). *)
  r = expr /. Power[b_, n_Integer] /; (n != 0 && ncExprQ[b]) :> MatrixPower[b, n];
  r = r /. {NonCommutativeMultiply -> Dot, tp -> Transpose,
            aj -> ConjugateTranspose, inv -> Inverse};
  If[Head[r] === Plus, r = Replace[r, c_?NumericQ :> c IdentityMatrix[dim], {1}]];
  r
];

(* ============================================================ *)
(* §4.6 graded non-commutative Neumann inverse                  *)
(*   inv[s - e] = Sum_k (inv[s]**e)^k ** inv[s], truncated at    *)
(*   weighted order n in the grading {e -> 1}.                   *)
(* ============================================================ *)
neumannInverse[s_, e_, n_Integer] :=
  NCExpand@Sum[
    NonCommutativeMultiply @@ Riffle[ConstantArray[inv[s], k + 1], ConstantArray[e, k]],
    {k, 0, n}];

(* transform: replace inv[s-e] by its order-n Neumann truncation (~ step) *)
expandInverse[s_, e_, n_Integer] :=
  Function[cur, Yields[neumannInverse[s, e, n], AsymEqual, "Neumann expansion of inv[s-e]"]];

(* ============================================================ *)
(* Verification by random-matrix substitution                   *)
(* ============================================================ *)

(* NC equality: NCExpand for a symbolic zero, random matrices as the probe. *)
ncSymbolicZeroQ[d_] := If[Quiet[NCExpand[d]] === 0, True, Unknown];

ncMatrixProbe[before_, after_, dim_: 3, trials_: 6] := Module[{syms, res, tol = 10.^-7},
  syms = ncSymbolsIn[{before, after}];
  res = Table[
    Module[{rules = (# -> RandomReal[{-1, 1}, {dim, dim}]) & /@ syms, lhs, rhs},
      Quiet@Check[
        lhs = toNum[before, dim] /. rules; rhs = toNum[after, dim] /. rules;
        If[MatrixQ[lhs] && MatrixQ[rhs] && Dimensions[lhs] === Dimensions[rhs],
          Norm[lhs - rhs] <= tol (1 + Norm[lhs]), $bad],
        $bad]],
    {trials}];
  res = DeleteCases[res, $bad];
  Which[res === {}, Unknown, MemberQ[res, False], False, True, True]
];

ncCertify[before_, after_, Equal, asm_] := Module[{sz, pr, status},
  sz = ncSymbolicZeroQ[before - after];
  pr = ncMatrixProbe[before, after];
  status = Which[pr === False, "Refuted", sz === True, "Verified",
                 pr === True, "NumericOnly", True, "Unverified"];
  <|"relation" -> Equal, "symbolic" -> sz, "numeric" -> <|"verdict" -> pr|>, "status" -> status|>
];
(* matrix (Loewner) ordering not yet supported -> honest Unverified *)
ncCertify[before_, after_, rel_, asm_] :=
  <|"relation" -> rel, "symbolic" -> Unknown, "numeric" -> <|"verdict" -> Unknown|>,
    "status" -> "Unverified"|>;

(* graded ~ for NC: confirm the residual before-after is of weighted order
   > n by checking how its norm scales as the small generators -> 0. *)
ncOrderProbe[diff_, smalls_, n_, dim_: 3, trials_: 3] := Module[{others, tnd, votes},
  tnd = toNum[diff, dim];   (* map heads first, then substitute numeric matrices *)
  others = Complement[ncSymbolsIn[diff], smalls];
  votes = Table[
    Module[{oR, sMats, normAt, r1, r2, e1 = 0.02, e2 = 0.01, p},
      oR = (# -> RandomReal[{-1, 1}, {dim, dim}]) & /@ others;
      sMats = RandomReal[{-1, 1}, {dim, dim}] & /@ smalls;
      (* substitute ALL symbols at once: a two-pass /. would leave e.g. (s-e)
         with one operand a matrix and the other a scalar symbol, which threads. *)
      normAt[eps_] := Quiet@Check[
        Norm[tnd /. Join[oR, MapThread[#1 -> eps #2 &, {smalls, sMats}]]], $bad];
      r1 = normAt[e1]; r2 = normAt[e2];
      Which[
        r1 === $bad || r2 === $bad, Indeterminate,
        r2 < 10.^-12, True,                            (* exact to this order *)
        True, p = Log[r1/r2]/Log[e1/e2]; p >= n + 0.5] (* residual is O(e^{n+1}) *)
    ], {trials}];
  votes = DeleteCases[votes, Indeterminate];
  Which[votes === {}, Unknown, Count[votes, True] >= Ceiling[Length[votes]/2.], True, True, False]
];

ncAsymCertify[before_, after_, asm_, grading_, order_] := Module[{smalls, v},
  If[grading === None || order === None,
    Return[<|"relation" -> AsymEqual, "symbolic" -> Unknown,
             "numeric" -> <|"verdict" -> Unknown|>, "status" -> "Unverified"|>]];
  smalls = First /@ normalizeGrading[grading];
  v = ncOrderProbe[before - after, smalls, order];
  <|"relation" -> AsymEqual, "symbolic" -> Unknown, "numeric" -> <|"verdict" -> v|>,
    "status" -> Which[v === True, "Verified", v === False, "Refuted", True, "Unverified"]|>
];
