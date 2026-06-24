# How verification works

Every `step` produces a **certificate** with a `"status"`:

| Status | Meaning |
|--------|---------|
| `Verified` | proven (symbolically, under the assumptions) |
| `NumericOnly` | supported by the numeric probe; not proven symbolically |
| `Unverified` | no evidence either way (e.g. an asymptotic step with no grading in scope) |
| `Refuted` | **disproven** — the asserted relation does not hold |

`verifiedQ[d]` is `True` when every step is `Verified` or `NumericOnly`. A
`Refuted` step still gets recorded (so you can see it), but emits a message and
fails `verifiedQ`.

The verifier dispatches on the *kind* of expression. Each domain has a probe
suited to it.

## Scalar expressions

`certify` checks `before R after` two ways:

- **symbolic** — `Simplify[before R after, assumptions]` → `True` / `False` / unknown;
- **numeric** — sample points satisfying the assumptions (`FindInstance` seed +
  jitter), evaluate, and test the relation with tolerance.

A flipped inequality or a multiply-by-maybe-negative is caught immediately:

```mathematica
Quiet @ step[derive[t, Assumptions -> t > 0], boundBy[t/2, LessEqual]]
(* status: Refuted  --  t <= t/2 is false for t > 0 *)
```

## Asymptotic equivalence (`~`)

`f ~ g` is verified **relative to a grading**: it holds iff `f - g` vanishes to the
derivation's `GradingOrder`. The check expands the difference with `seriesExpand`
and confirms it is zero to that order. Without a grading in scope, a `~` step is
honestly `Unverified`.

```mathematica
derive[1/(s - e), Grading -> {e -> 1}, GradingOrder -> 2] // step[dropHigherOrder[]]
(* the ~ step is Verified: the dropped remainder is genuinely O(e^3) *)
```

## Non-commutative / matrix expressions

Identities in `**`, `tp`, `aj`, `inv` are checked by **substituting random
concrete matrices** (mapping `**`→`Dot`, `inv`→matrix inverse, `tp`→`Transpose`,
…) and comparing. This catches mistakes that symbolic simplification can mask:

```mathematica
ncDeclare[x, y];
Quiet @ step[derive[x ** y], # /. x ** y -> y ** x &]
(* status: Refuted  --  matrices don't commute *)
```

Two refinements make the probe trustworthy on structured problems:

- **Side relations.** With `Relations -> {A ** w -> 0}`, the probe samples random
  matrices/vectors that *satisfy* the relation (it draws `w`, then builds `A`
  annihilating it), so "this term vanishes because `A w = 0`" is checked against
  genuine constrained data.
- **Symmetry.** `ncDeclareSym[A]` samples `A` as symmetric positive-definite — so
  identities that hold only for symmetric `A` (e.g. completing a quadratic form)
  verify, while a generic `A` is correctly **Refuted**.

For an asymptotic NC step, the probe confirms the residual scales at the right
order as the small generators \(\to 0\).

## Held integrals and sums

- **Integrals** (`Inactive[Integrate]`): a *numeric quadrature* probe substitutes
  random parameters, maps `Inactive[Integrate]`→`NIntegrate`, and compares — plus a
  time-bounded symbolic `Activate` check. A forgotten Jacobian is caught as
  `Refuted`.
- **Sums** (`Inactive[Sum]`): finite sums `Activate` to explicit term sums, so
  `Simplify` proves the equality, backed by a random-parameter numeric check. A
  reindex that forgets to adjust the summand is `Refuted`.

## Honesty about scope

If the verifier cannot establish a relation, it says `Unverified` rather than
pretending. Notably, **named probabilistic theorems** (Slepian, Borell–TIS,
Piterbarg) are *asserted results*, not numerically checkable in this framework;
they are deliberately not dressed up as `Verified`. See
**[Core vs domain packs](domain-packs.md)**.
