# Getting started

## Requirements

- **Mathematica / Wolfram Engine** 13.0 or later.
- **[NCAlgebra](https://github.com/NCAlgebra/NC) 6.x** — used as the
  non-commutative backend. Install once:
  ```mathematica
  PacletInstall["NCAlgebra"]
  ```
  FormalCalc loads it automatically (banner suppressed). The matrix / NC features
  need it; the rest of the toolkit works without ever touching it.

## Loading the package

The toolkit is loaded directly from its master file:

```mathematica
Get["/path/to/mathematica-toolkit/Kernel/FormalCalc.wl"];
```

This brings the general-purpose core into the `` FormalCalc` `` context. Domain
packs (e.g. the Gaussian pack) are **not** loaded by the core — you bring them in
explicitly when you need them:

```mathematica
Get["/path/to/mathematica-toolkit/Source/Domain/Gaussian.wl"];   (* FormalCalc`Gaussian` *)
```

!!! tip "Running headless"
    Everything works under `wolframscript` for scripted/batch use:
    ```bash
    wolframscript -file my_derivation.wl
    ```
    In `.wl` scripts a line may not *start* with `//`; either keep a chain on one
    line or use sequential reassignment (`d = step[d, ...]`), which reads cleanly
    and is the style used throughout these docs.

## Your first derivation

A derivation starts from an expression and grows by applying transformations.
Each `step` performs a move and verifies the relation it asserts.

```mathematica
d = derive[(a + b)^2];
d = step[d, rewrite[(a + b)^2 -> a^2 + 2 a b + b^2], "expand the square"];
d = step[d, dropTerm[a^2], "drop a^2 >= 0  (lower bound)"];
```

Inspect it with the accessors:

```mathematica
result[d]       (* 2 a b + b^2                  - the current expression       *)
relationOf[d]   (* GreaterEqual                 - start-to-finish relation     *)
verifiedQ[d]    (* True                         - every step checked out       *)
stepsOf[d]      (* the full record, with a certificate per step                *)
```

The first step is an **equality** (`=`), the second a **lower bound** (`≥`); the
chain composes them to `≥` automatically. The expansion is verified symbolically,
and `a^2 ≥ 0` is confirmed before the drop is accepted.

!!! note "Notebook display"
    In a notebook a `Derivation` renders as an aligned, framed chain with a
    ✓ / ✗ mark per step. In a terminal, use the accessors (or the `showChain`
    helper from `examples/util.wl`).

## The shape of every computation

1. **`derive[expr, …]`** — start from your expression and attach context *once*:
   `Assumptions`, `Grading`/`GradingOrder` (for asymptotics), `Relations` (for
   non-commutative side relations).
2. **`step[d, move, "note"]`** — name a move; the CAS performs it and verifies the
   asserted relation. Inferring moves ask for the minimum and read context from
   the derivation; explicit forms remain for full control.
3. **Read the chain** — `result`, `relationOf`, `verifiedQ`, `stepsOf`. The
   `Derivation` *is* the proof.

Continue with **[The derivation chain](concepts/derivations.md)**.
