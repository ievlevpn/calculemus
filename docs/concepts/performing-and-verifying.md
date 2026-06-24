# Performing & verifying

FormalCalc is built to **perform** transformations, not merely to certify ones you
typed by hand. The verification is a silent safety net underneath — valuable, but
not the product.

## Perform first; verify underneath

Transforms *do the algebra* and **infer what they can**, so you specify the
minimum:

| You write | The CAS computes |
|-----------|------------------|
| `changeVar[u, phi]` | the new integration limits (by solving `phi = old limit`) and the Jacobian |
| `ibp[u]` | the antiderivative `v` of the rest, the boundary term, and the remainder |
| `dropHigherOrder[]` | reads `Grading`/`GradingOrder` off the derivation and expands+truncates |
| `applyRel[]` | reads `Relations` off the derivation and applies them |
| `neumannInverse[s, e, n]` | the full non-commutative operator series |
| `completeSquare[x]` | the completed quadratic |

!!! note "The one thing the tool won't invent"
    A genuinely free **mathematical choice** — which way a bound goes, which
    substitution to try, which factor to integrate by parts. There you *name* the
    move and the CAS executes it. Every inferring transform keeps an explicit form
    (`changeVar[u, phi, {a, b}]`, `ibp[u, v]`, `dropHigherOrder[g, n]`,
    `applyRel[rules]`), so generality is never sacrificed.

## The transform protocol

A **transform** is just a function of the current expression. Its return value
tells `step` what relation was asserted:

```mathematica
(* equality step: return a bare expression *)
myExpand = Function[cur, Expand[cur]];

(* relation-changing step: return Yields[expr, relation, note] *)
dropTerm[t_] := Function[cur, Yields[cur - t, GreaterEqual, "drop nonneg term"]];
```

That's the entire contract — no transform registry, no special objects. Because
transforms are plain functions, **any** Wolfram function is a transform:

```mathematica
d = step[d, Expand];        (* equality, verified *)
d = step[d, NCExpand];      (* NCAlgebra expansion, verified by random matrices *)
d = step[d, Activate];      (* evaluate held integrals/sums, verified *)
d = step[d, # /. x -> -x &] (* an ad-hoc rewrite, verified *)
```

### Context-aware transforms

Some moves need the context you set on `derive` (grading, relations…). They are
written as `WithContext[(expr, ctx) -> result]`; `step` passes the context
association. This is how `dropHigherOrder[]` and `applyRel[]` avoid making you
repeat the grading/relations:

```mathematica
d = derive[1/(s - e), Grading -> {e -> 1}, GradingOrder -> 2];
d = step[d, dropHigherOrder[]];   (* reads {e -> 1} and order 2 from d *)
```

`ctx` is `<|"grading" -> …, "order" -> …, "relations" -> …, "assumptions" -> …|>`.

## Two-layer design

The math and the bookkeeping are decoupled:

- **Layer 1 — transforms** are pure functions on expressions, individually
  testable, with no notion of a derivation.
- **Layer 2 — the `Derivation`** is a thin orchestration that applies a transform,
  runs the verifier, and records the step.

A consequence worth knowing: domain packs (like the Gaussian pack) only *provide*
transforms; verification lives in the core and runs automatically. A pack never
needs privileged access. See **[Core vs domain packs](domain-packs.md)**.
