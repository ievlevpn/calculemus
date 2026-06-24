# Getting started

FormalCalc is built for working **in a Mathematica notebook** — you evaluate one
cell at a time, see the derivation grow, and decide the next move from what's in
front of you. This page walks through that workflow from scratch.

## Requirements

- **Mathematica** 13.0 or later (notebook front-end recommended; a Wolfram Engine works for scripts).
- **[NCAlgebra](https://github.com/NCAlgebra/NC) 6.x** — the non-commutative backend. Install once:
  ```mathematica
  PacletInstall["NCAlgebra"]
  ```
  FormalCalc loads it automatically (banner suppressed). Only the matrix / non-commutative features need it; everything else works without it.

## Loading it

In a fresh notebook, evaluate one cell (`⇧↵`) at the top:

```mathematica
Get["/path/to/mathematica-toolkit/Kernel/FormalCalc.wl"]
```

That brings the general-purpose core into the `` FormalCalc` `` context. A
field-specific pack (e.g. Gaussian) is **not** loaded by the core — add it only if
you need it:

```mathematica
Get["/path/to/mathematica-toolkit/Source/Domain/Gaussian.wl"]
```

As soon as it's loaded you have **autocomplete and tooltips** — see
[Notebook assistance](#notebook-assistance) at the bottom.

## Your first derivation (the notebook way)

The natural notebook style is **tactic mode**: start a computation, then add one
verified line per cell. Evaluate these in separate cells:

```mathematica
compute[(a + b)^2]
```

The output is a **live `Derivation` object** — a small panel showing the current
expression and its status. Click its ▸ triangle to expand the full annotated
chain. Now add a line (a new cell):

```mathematica
by[rewrite[(a + b)^2 -> a^2 + 2 a b + b^2], "expand the square"]
```

The panel updates: a `=` line, the expanded result, a green ✓, and your note in
the margin. Add another:

```mathematica
by[dropTerm[a^2], "drop a^2 >= 0"]
```

Now it shows a `≥` line — the running relation has composed `=` then `≥` into `≥`,
and `a^2 ≥ 0` was checked before the drop was accepted. Changed your mind about a
step?

```mathematica
undo[]   (* steps the computation back one line *)
```

!!! tip "It reads like a margin"
    `by[…]` is exactly the annotation you'd scribble beside a hand derivation —
    "by parts", "by AM–GM", "by Fubini" — except the CAS *computes* the new line
    and *verifies* it. You never type the result, so the error-prone part is gone.

## Reading the result

`goal[]` is the current state; the accessors read it:

```mathematica
result[goal[]]      (* 2 a b + b^2   — the current expression          *)
relationOf[goal[]]  (* GreaterEqual  — start-to-finish relation        *)
verifiedQ[goal[]]   (* True          — every step checked out          *)
caveats[goal[]]     (* anything taken on faith (claims / unverified)   *)
```

The `Derivation` panel *is* the proof — keep it as the cell output and it's a
self-contained, checkable record.

## Entering integrals and sums

Write held (unevaluated) integrals/sums with the short constructors — or type the
inactive `∫` / `∑` directly with Mathematica's 2-D input:

```mathematica
dint[f, {x, a, b}]    (* a definite integral, kept inert *)
sum[f, {k, a, b}]     (* a held sum                      *)
```

```mathematica
compute[dint[x^2 Exp[x], {x, 0, 1}]]
by[ibp[x^2]]          (* integration by parts; the CAS finds the antiderivative *)
```

## The shape of every computation

1. **`compute[expr]`** — start; attach context *once* via options
   (`Assumptions`, `Grading`/`GradingOrder`, `Relations`). `compute[L <= M]` starts
   a [two-sided](reference/twosided.md) relation instead.
2. **`by[move]`** / **`by[move, "note"]`** — add a verified line; `undo[]` to back up.
3. **Read** `goal[]` / `result` / `verifiedQ` / `caveats`.

!!! note "Functional style (scripts, branching, one cell)"
    The same engine is available functionally: `d = derive[expr]` then
    `d = step[d, move]`, or a one-cell pipeline
    `derive[expr] ▷ move1 ▷ move2` (the `▷` operator — see below). Use this for
    reproducible scripts or when you want to keep several branches as named values.

## Notebook assistance

Once loaded in a notebook you get, automatically:

- **Autocomplete** of function names (type `comp`⇥ → `compute`, `completeSquare`, …), each with its one-line description.
- **Tooltips** — hover, `?function`, or ⌘⇧K shows what a function does and its arguments.
- **Argument hints + checking** — typing `compute[` shows the argument layout, and a wrong number of arguments is flagged.
- **Value suggestions** — typing `useIneq["` pops up the registered inequality names.
- **`▷` operator** — type `Esc` `|>` `Esc` to enter it (for one-cell `derive[…] ▷ … ▷ …` chains).

The last two install automatically when a notebook front-end is present; re-run
`installAssistance[]` if needed.

!!! info "Running headless"
    Everything also works under `wolframscript` for batch use
    (`wolframscript -file my.wl`). One caveat: in a `.wl` *script* a line may not
    *begin* with `//` or `▷`, so use sequential `d = step[d, …]` or keep a chain on
    one line. In the **notebook**, tactic mode (`compute` / `by`, one cell each)
    sidesteps this entirely.

Continue with **[Notation & workflow](concepts/notation.md)** and
**[The derivation chain](concepts/derivations.md)**.
