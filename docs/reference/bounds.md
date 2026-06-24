# Reference — Bounds & inequalities

Single-quantity bounding (`Source/Bounds.wl`). These transforms produce a bound
and assert the direction; the verifier confirms it (a wrong direction is
`Refuted`). The running relation is composed across the chain.

## `signOf`

```mathematica
signOf[expr]              signOf[expr, assumptions]
```

Return `Positive`, `Negative`, `NonNegative`, `NonPositive`, or `Unknown`. Uses
cheap structural recognizers (squares, even powers, `Abs`, sums of nonnegatives)
then falls back to `Simplify`.

```mathematica
signOf[x^2]          (* NonNegative *)
signOf[t, t > 0]     (* Positive    *)
```

## `dropTerm`

```mathematica
dropTerm[term]   (* drop a NONNEGATIVE term: current >= current - term  (>= step) *)
```

Mirrors the textbook "drop the \(\ge 0\) remainder to get a lower bound" move
(`Plus` auto-cancels `term` if it is a literal summand):

```mathematica
derive[2 lead + remainder^2, Assumptions -> lead > 0]
  // step[dropTerm[remainder^2]]
(* >=  2 lead   [Verified: remainder^2 >= 0] *)
```

## `boundBy`

```mathematica
boundBy[newExpr]            (* assert current <= newExpr (LessEqual default) *)
boundBy[newExpr, relation]  (* assert current `relation` newExpr             *)
```

The general "replace the whole expression by a claimed bound" move; the verifier
checks the claim under the assumptions.

```mathematica
derive[t, Assumptions -> t > 0] // step[boundBy[t + t^2, LessEqual]]   (* Verified *)
Quiet @ step[derive[t, Assumptions -> t > 0], boundBy[t/2, LessEqual]] (* Refuted  *)
```

## `boundSub`

```mathematica
boundSub[rule]             boundSub[rule, relation]
```

Bound a subterm via `rule`, asserting `relation` for the whole expression (default
`LessEqual`); verified.

!!! info "Sign of the dropped term"
    `dropTerm` is for **nonnegative** terms (giving `≥`). To loosen with a
    nonpositive term or any other directed bound, use `boundBy` / `boundSub` and
    state the relation — the verifier keeps you honest.

!!! tip "Named inequalities"
    For standard inequalities (triangle, AM–GM, Young, `1+x ≤ eˣ`, …) and your own
    assumed bounds — applied as directional rewrites with **accumulated
    side-conditions** — see [Inequalities](inequalities.md).
