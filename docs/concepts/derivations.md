# The derivation chain

The central object is a **`Derivation`**: a single quantity transformed through a
chain of verified steps,

\[
e_0 \;\mathbin{R_1}\; e_1 \;\mathbin{R_2}\; e_2 \;\mathbin{R_3}\; \dots
\]

where each \(R_i\) is one of `Equal`, `LessEqual`, `GreaterEqual`, `Less`,
`Greater`, or `AsymEqual` (\(\sim\), asymptotic equivalence). Equalities and
inequalities are the *same* object: an ordinary equational derivation is just a
chain whose relations are all `=`. This is why bounding a quantity and rewriting
it use the same machinery.

!!! abstract "Single-quantity chain"
    A `Derivation` tracks **one evolving expression** and its relation back to the
    start — the dominant pattern in analysis (*bound this quantity through a chain
    of relations*). Manipulating a two-sided equation (`apply f to both sides`) is
    a different, planned object.

## Building a chain

```mathematica
d = derive[expr, Assumptions -> asm, Grading -> g, GradingOrder -> n, Relations -> rels];
d = step[d, transform, "human note"];
```

`derive` attaches the **context** once; every later step reads it. `step` applies
one transform, verifies the relation it asserts, appends a record, and returns a
*new* derivation (the object is immutable — `step` never mutates `d`).

### Curried / chained forms

`step` has a curried form for `//`-pipelines, convenient in notebooks:

```mathematica
derive[(a + b)^2]
  // step[rewrite[(a + b)^2 -> a^2 + 2 a b + b^2]]
  // step[dropTerm[a^2], "drop a^2 >= 0"]
```

!!! warning "In `.wl` scripts"
    A script line cannot *begin* with `//`. Either keep the chain on one line, end
    lines with a trailing `//`, or use sequential reassignment
    `d = step[d, …]` (used throughout these docs).

## Inspecting a derivation

| Accessor | Returns |
|----------|---------|
| `result[d]` | the current (last) expression |
| `relationOf[d]` | the composed start-to-current relation |
| `assumptionsOf[d]` | the assumptions in force |
| `stepsOf[d]` | the list of step records |
| `verifiedQ[d]` | `True` iff every step verified (`Verified` or `NumericOnly`) |

Each entry of `stepsOf[d]` is an association with keys `"result"`, `"relation"`,
`"note"`, and `"cert"` (the verification certificate, whose `"status"` is one of
`Verified` / `NumericOnly` / `Unverified` / `Refuted`).

## How relations compose

The running relation is the transitive composition of the step relations:

- `=` ∘ \(R\) = \(R\) (an equality never changes the running relation);
- `≤` ∘ `≤` = `≤`,  `<` ∘ `≤` = `<`,  and so on;
- mixing `≤` with `≥` is **incomparable** → `composeRelation` returns `$Failed`
  with a message (you cannot silently chain a lower and an upper bound).

```mathematica
relationOf[
  derive[(p + q)^2 + r^2]
    // step[rewrite[(p + q)^2 -> p^2 + 2 p q + q^2]]   (* = *)
    // step[dropTerm[r^2]]                              (* >= *)
]
(* GreaterEqual *)
```

## What a step asserts

A transform returns either a bare expression (the step is an **equality**) or a
tagged `Yields[newExpr, relation, note]` to assert a different relation. You
rarely write `Yields` yourself — bounding transforms emit it for you. See
**[Performing & verifying](performing-and-verifying.md)** for the transform
protocol, and **[How verification works](verification.md)** for what "verified"
means in each domain.
