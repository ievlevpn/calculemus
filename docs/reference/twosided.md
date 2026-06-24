# Reference — Two-sided (in)equations

A `Derivation` tracks **one** quantity. Some moves are inherently about a
relation between **two** sides — applying the same operation to both — which the
single-quantity chain cannot express. The canonical example:

\[
\ln P \le B \;\Longrightarrow\; P \le e^{B} \qquad\text{(apply } \exp \text{ to both sides).}
\]

`Source/TwoSided.wl` provides that object (`Source/TwoSided.wl`).

## Starting one

```mathematica
relate[L, R, M]       (* e.g. relate[Log[P], LessEqual, B] *)
relate[L <= M]        (* or pass the relation directly: relate[Log[P] <= B] *)
relate[L <= M, Assumptions -> asm]
```

## Applying an operation to both sides

```mathematica
stepBoth[obj, op]     stepBoth[obj, op, "note"]
stepBoth[op]          (* curried, for // *)
```

| op | effect |
|----|--------|
| `addBoth[c]` / `subtractBoth[c]` | `L ± c R M ± c` (relation preserved) |
| `mulBoth[c]` | `L c R' M c` — relation **flips** when `c` is provably negative |
| `applyBoth[f]` | `f[L] R f[M]` — assumes `f` increasing (verified); `applyBoth[f, "Decreasing"]` flips |
| `rewriteBoth[rule]` | rewrite both sides via `rule` |

```mathematica
relate[Log[P], LessEqual, B] // stepBoth[applyBoth[Exp], "exponentiate both sides"]
(* P <= e^B ,  verified *)

relate[x <= y] // stepBoth[mulBoth[-2]]
(* -2 x >= -2 y ,  relation flipped *)
```

## Accessors

```mathematica
lhsOf[obj]   rhsOf[obj]   relationOf[obj]   stepsOf[obj]   verifiedQ[obj]
```

## How a step is verified

Each step asserts a new relation `L' R' M'` that must **follow from** the old
`L R M`. It is checked as an *implication*: sample points where the premise
`L R M` holds (over a symmetric numeric range, so order-reversing counterexamples
are found) and confirm the conclusion `L' R' M'` there, plus a symbolic `Implies`
check.

So monotone operations verify, and a non-monotone one is caught:

```mathematica
Quiet @ stepBoth[relate[x <= y], applyBoth[#^2 &]]
(* Refuted:  x <= y does NOT give x^2 <= y^2  (x = -3, y = 1) *)

relate[x <= y, Assumptions -> 0 <= x] // stepBoth[applyBoth[#^2 &]]
(* Verified:  squaring is order-preserving for nonnegatives *)
```

!!! note "vs. the single-quantity chain"
    Use a [`Derivation`](../concepts/derivations.md) to **bound one quantity**
    through a chain (`P{…} ≤ … ≤ bound`). Use a two-sided relation to **transform a
    known relation between two sides** — solving, rearranging, or pushing a bound
    through a monotone function.
