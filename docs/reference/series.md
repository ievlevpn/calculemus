# Reference — Series & asymptotics

Graded truncation and weighted series expansion (`Source/Series.wl`). This is the
spine for asymptotic work.

## Gradings

A **grading** assigns each "small" generator a positive weight; the weight of a
monomial \(\prod g_i^{p_i}\) is \(\sum p_i w_i\). Specify it as a list:

```mathematica
{e -> 1}            (* e has weight 1                 *)
{x, y}              (* both weight 1 (shorthand)      *)
{x -> 1/2, y -> 1/2} (* fractional weights             *)
```

```mathematica
normalizeGrading[g]            (* canonicalize to {gen -> weight, ...}  *)
monomialWeight[monomial, g]    (* weighted degree of a single monomial  *)
```

## `truncate`

```mathematica
truncate[expr, grading, order]
truncate[expr, grading, order, assumptions]
```

Keep the monomials of `expr` (assumed polynomial in the generators) whose weighted
degree is `≤ order`. Handles **symbolic** exponents, so the paper's \(t^\beta\)
grading works:

```mathematica
truncate[c0 + c1 t^b + c2 t^(2 b), {t}, b, b > 0]   (* c0 + c1 t^b *)
```

## `seriesExpand`

```mathematica
seriesExpand[expr, grading, order]
seriesExpand[expr, grading, order, assumptions]
```

Expand `expr` to weighted `order` in the graded generators — including
reciprocals, `Exp`, `Log`, composites — via ε-homogenization (substitute
\(g \to \varepsilon^{w} g\), take the native series in ε, set \(\varepsilon = 1\)).
Rational weights + numeric order get the full expansion; otherwise it falls back
to polynomial truncation.

```mathematica
seriesExpand[1/(s - e), {e -> 1}, 2]   (* 1/s + e/s^2 + e^2/s^3 *)
seriesExpand[Log[1 + x], {x}, 3]       (* x - x^2/2 + x^3/3     *)
```

## `dropHigherOrder`

```mathematica
dropHigherOrder[grading, order]   (* explicit                                  *)
dropHigherOrder[]                 (* reads Grading/GradingOrder from derive     *)
```

The transform that expands and drops terms above the weighted order, asserting an
asymptotic-equivalence (`~`) step. **Auto-verified** when the derivation carries a
matching grading (the residual is checked to vanish to that order):

```mathematica
derive[1/(s - e), Assumptions -> s > 0, Grading -> {e -> 1}, GradingOrder -> 2]
  // step[dropHigherOrder[]]
(* ~  1/s + e/s^2 + e^2/s^3   [Verified] *)
```

## `o` / `O` markers

```mathematica
littleO[scale]   bigO[scale]
```

Lightweight bookkeeping markers, idempotent under addition and absorbing nonzero
numeric factors (`littleO[s] + littleO[s]` → `littleO[s]`, `bigO[s]` absorbs
`littleO[s]`).

!!! note "Operator / matrix series"
    The non-commutative analogue — the Neumann expansion of a perturbed inverse —
    is [`neumannInverse` / `expandInverse`](matrix.md) in the Matrix module, and
    composes with these gradings.
