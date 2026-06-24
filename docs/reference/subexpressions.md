# Reference — Addressing subexpressions

The everyday pain in any CAS: you *see* a subexpression but can't easily *address*
it, because the tree (and `FullForm`) don't match your eye — `eˣ` is
`Power[E, x]`, `√x` is `Power[x, 1/2]`, `a/b` is `Times[a, Power[b, -1]]`.
FormalCalc lets you point at a piece the way you'd say it.

## Locators — *where*

| locator | addresses |
|---------|-----------|
| `integrand` | the body of a held integral |
| `summand` | the body of a held sum |
| `argOf[Exp]` | the exponent of `eˣ` (i.e. inside the exponential) |
| `argOf[Sqrt]` | the radicand |
| `argOf[Log]`, `argOf[Sin]`, … | the argument of that function |
| `numerator`, `denominator` | numerator / denominator |
| `term[n]`, `firstTerm`, `lastTerm` | an additive term |
| `factor[n]` | a multiplicative factor |
| a **pattern** (e.g. `_^2`, `_Plus`) | every matching subexpression |
| a **concrete subexpression** (e.g. `x^3`) | that exact piece |

## See what you're pointing at

```mathematica
partOf[ dint[x^2 + x, {x, 0, 1}], integrand ]      (* x^2 + x *)
partOf[ Exp[-(a/2) x^2 + b x], argOf[Exp] ]         (* -(a/2) x^2 + b x *)
partOf[ a/b, denominator ]                          (* b *)
partOf[ p + q + r, term[2] ]                        (* q *)
```

`highlight[expr, where]` shows the whole expression with the addressed piece
boxed — useful to confirm before you act.

## Operate — `on[where, op]`

`on[where, op]` applies the transform `op` at the located subexpression(s) and
verifies the **whole** step.

```mathematica
(* expand / factor inside a part *)
derive[dint[x^2 + 2 x + 1, {x, 0, 1}]] // step[on[integrand, Factor]]
(* integrand becomes (1 + x)^2 *)

(* complete the square INSIDE the exponential (the Gaussian move) *)
derive[Exp[-(a/2) x^2 + b x]] // step[on[argOf[Exp], completeSquare[x]]]

(* operate on one term only *)
derive[u + (m + n)^2] // step[on[term[2], Expand]]   (* u + m^2 + 2 m n + n^2 *)

(* a pattern: expand every square *)
derive[(p + q)^2 + (r + s)^2] // step[on[(_Plus)^2, Expand]]
```

In tactic mode this reads like a margin note:

```mathematica
by[ on[integrand, Expand] ]
by[ on[argOf[Log], factor] ]
```

!!! note "Direction is still verified"
    `on` works for equality ops (expand, factor, complete-the-square, a rewrite)
    *and* for bounds. A bound applied where the surrounding context reverses its
    direction — e.g. enlarging a **denominator** — is **Refuted**, because the
    whole-expression relation is what gets checked. Inequality side-conditions
    raised inside a part are accumulated just as elsewhere.
