# Reference — Matrix & non-commutative

Non-commutative / matrix algebra (`Source/Matrix.wl`), with
[NCAlgebra](https://github.com/NCAlgebra/NC) as the backend. NCAlgebra's notation
is used directly: `**` (non-commutative product), `tp` (transpose), `aj`
(adjoint), `inv` (inverse), `NCExpand`, `NCCollect`, … Calculemus adds graded
expansions, side-relation application, and **random-matrix verification**.

## Declaring symbols

```mathematica
ncDeclare[A, B, ...]      (* non-commutative matrices/operators              *)
ncDeclareVec[w, b, ...]   (* column vectors (shape d x 1 in verification)    *)
ncDeclareSym[S, ...]      (* symmetric matrices (sampled SPD in verification) *)
```

Declaration drives both NCAlgebra (so `**` treats them correctly) and the
verifier's random sampling. Multi-letter symbols *must* be declared; NCAlgebra
already treats single lowercase letters as non-commutative.

!!! warning "Verification shapes"
    The random-matrix probe needs to know shapes: matrices → `d×d`, vectors →
    `d×1`, symmetric → SPD. Declare accordingly, or a quadratic form / inverse may
    not verify.

## Symmetric / antisymmetric parts

```mathematica
symPart[a]    (* (a + tp[a])/2 *)
antiPart[a]   (* (a - tp[a])/2 *)
```

## Quadratic forms

```mathematica
quadForm[A, c, x]            (* tp[x]**A**x + tp[x]**c + tp[c]**x *)
```

### `completeSquareMat`

```mathematica
completeSquareMat[A, c, x]
```

The completed square of `quadForm[A, c, x]` for **symmetric** `A`:

\[
x^\top A x + x^\top c + c^\top x \;=\; (x + A^{-1}c)^\top A (x + A^{-1}c) - c^\top A^{-1} c.
\]

```mathematica
ncDeclareSym[A]; ncDeclareVec[c, x];
derive[quadForm[A, c, x]] // step[completeSquareMat[A, c, x] &]   (* Verified *)
```

Symmetry is load-bearing: declaring `A` with `ncDeclare` (generic) instead of
`ncDeclareSym` makes the same step **Refuted**.

## Neumann expansion of a perturbed inverse

```mathematica
neumannInverse[s, e, n]    (* Sum_{k=0}^n (inv[s]**e)^k ** inv[s]  *)
expandInverse[s, e, n]     (* transform: inv[s-e] |-> its order-n truncation (~ step) *)
```

`expandInverse` asserts an asymptotic-equivalence step, verified by a random-matrix
order probe (the residual is checked to be \(O(e^{n+1})\)) when the derivation
carries `Grading -> {e -> 1}, GradingOrder -> n`:

```mathematica
ncDeclareSym[S]; ncDeclare[V];
derive[inv[S - V], Grading -> {V -> 1}, GradingOrder -> 2]
  // step[expandInverse[S, V, 2]]
(* ~  inv[S] + inv[S]**V**inv[S] + inv[S]**V**inv[S]**V**inv[S]   [Verified] *)
```

## Side relations

```mathematica
applyRel[rules]   (* apply NC side relations, e.g. {A ** w -> 0} (NCAlgebra-aware) *)
applyRel[]        (* reads Relations from the derivation                            *)
```

Verified by sampling random matrices/vectors that *satisfy* the relations:

```mathematica
ncDeclare[A]; ncDeclareVec[w];
derive[tp[w] ** (A + tp[A]) ** w, Relations -> {A ** w -> 0, tp[w] ** tp[A] -> 0}]
  // step[NCExpand]
  // step[applyRel[]]
(* =  0   [Verified: w^T A w and w^T A^T w both vanish when A w = 0] *)
```
