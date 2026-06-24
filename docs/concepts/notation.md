# Notation & workflow

FormalCalc offers two ways to drive a computation. They share the same engine and
the same verification — pick whichever reads better for the task.

## Tactic mode (paper style)

The natural way to work incrementally — page after page — adding one **verified
line at a time**. It reads like the margin annotations of a hand derivation, and
needs no reassignment.

```mathematica
compute[ dint[x^3/(E^x - 1), {x, 0, Infinity}], Assumptions -> x > 0 ]
by[ rewrite[1/(E^x - 1) -> sum[E^(-k x), {k, 1, Infinity}]], "geometric series" ]
by[ fubini ]
by[ evaluate ]
```

| command | meaning |
|---------|---------|
| `compute[expr]` | start a computation (a "page"); `compute[L <= M]` starts a [two-sided](../reference/twosided.md) one |
| `by[op]` / `by[op, "note"]` | add a verified line by applying `op` (and an optional margin note) |
| `undo[]` | step back one line |
| `goal[]` | the current state (`result[goal[]]`, `verifiedQ[goal[]]`, …) |

Each `by[…]` shows the growing chain, so a mistake is visible immediately — and
`undo[]` lets you back out a move you didn't want.

## Functional style

For scripts, branching, or one-cell chains, build a [`Derivation`](derivations.md)
explicitly. The `>op>` operator (entered as `\[RightTriangle]`) chains moves:

```mathematica
derive[(p + q)^2] \[RightTriangle] rewrite[(p + q)^2 -> p^2 + 2 p q + q^2] \[RightTriangle] drop[p^2]
```

or the pipe form `derive[expr] // step[op] // step[op]`, or sequential
`d = step[d, op]`. All equivalent.

## Verbs

Operations read like mathematics:

| verb | does |
|------|------|
| `expand`, `factor`, `Simplify`, … | any Wolfram function is a transform |
| `ibp[u]` | integration by parts (computes `v`) |
| `changeVar[u, phi]` | change of variables (solves the limits) |
| `fubini` | interchange a sum and an integral |
| `evaluate` | activate held integrals/sums (`Activate`) |
| `drop[t]` | drop a nonnegative term (`≥`) |
| `atMost[x]` / `atLeast[x]` | assert `≤ x` / `≥ x` |
| `let[w, expr]` | name a subexpression `w := expr` |
| `amgm[a,b]`, `triangleIneq[a,b]`, `young[a,b,p,q]`, `bernoulli[x,r]`, `expBound[x]`, `logBound[x]` | standard inequalities |

## Pointing at subexpressions

Operate on a piece the way you *see* it — `on[integrand, Expand]`,
`on[argOf[Exp], completeSquare[x]]`, `on[term[2], Factor]`, `on[_^2, Expand]` —
and `partOf` / `highlight` to confirm what you're addressing. See
[Addressing subexpressions](../reference/subexpressions.md).

## Held integrals and sums

Write held (unevaluated) integrals and sums with the constructors — short forms of
the underlying `Inactive[Integrate]` / `Inactive[Sum]`:

```mathematica
dint[f, {x, a, b}]   (* definite integral, Inactive[Integrate][f, {x, a, b}] *)
iint[f, x]           (* indefinite integral                                  *)
sum[f, {k, a, b}]    (* held sum, Inactive[Sum][f, {k, a, b}]                 *)
```

In a notebook you can also type the inactive `∫`/`∑` directly; the constructors are
the convenient text form.
