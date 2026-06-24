# FormalCalc

**Verifiable, step-by-step formal manipulation in Mathematica.**

FormalCalc is a Mathematica toolkit for the long computations you'd normally do on
paper — page after page — except you do them **in a notebook**, one cell at a
time, and the CAS *performs* each move and *checks* it. One unnoticed slip on page
3 no longer quietly ruins everything after it. It targets work where you want
correct formal manipulation, not numeric evaluation: series and asymptotic
expansions, formal integrals and sums, non-commutative / matrix algebra, and
chains of inequalities.

!!! quote "The idea in one line"
    In each notebook cell you name a move; the CAS does the algebra and verifies
    it; the cell shows the derivation so far, and that **derivation is the proof**.

## A first taste

Open a notebook, load the package, and evaluate these as **separate cells**
(`⇧↵`). A genuinely hard improper integral, one verified line per cell:

```mathematica
Get["/path/to/mathematica-toolkit/Kernel/FormalCalc.wl"]    (* once, at the top *)

compute[ dint[x^3/(E^x - 1), {x, 0, Infinity}], Assumptions -> x > 0 ]
by[ rewrite[1/(E^x - 1) -> sum[E^(-k x), {k, 1, Infinity}]], "geometric series" ]
by[ fubini ]
by[ evaluate ]
```

Each cell returns a **live `Derivation` panel** — click ▸ to expand the full
annotated chain, with a ✓ on every verified line. Read off the answer:

```mathematica
result[goal[]]     (* Pi^4/15 *)
verifiedQ[goal[]]  (* True    *)
```

You supplied the one insight (the geometric series); the CAS swapped the sum and
integral, integrated each term, summed the series, and verified every line —
written just like the margin of a hand derivation, one `by[…]` per cell.

→ New here? Start with **[Getting started](getting-started.md)** for the full
notebook walkthrough.

## What makes it different

<div class="grid cards" markdown>

-   :material-cog-play: **Performs, not just checks**

    Transforms *do the algebra* — Jacobians, antiderivatives, series expansions,
    square completions — and infer what they can so you specify the minimum.

-   :material-shield-check: **Every step is verified**

    Each step asserts a relation; the package checks it — symbolically and with a
    numeric probe matched to the domain (random matrices, quadrature, finite-sum
    evaluation). A flipped sign is caught instantly.

-   :material-link-variant: **The chain is the proof**

    A derivation is a chain \(e_0 \mathbin{R_1} e_1 \mathbin{R_2} \dots\) of
    equalities *and* inequalities, with the running relation composed for you.

-   :material-layers-outline: **Formal, not numeric**

    Integrals, sums and derivatives stay inert (`Inactive`) until you choose to
    activate them. No convergence requirements — formal manipulation is enough.

</div>

## Where to go next

- **[Getting started](getting-started.md)** — load the package and walk through your first derivation.
- **[The derivation chain](concepts/derivations.md)** — the central object and how `step` works.
- **[Performing & verifying](concepts/performing-and-verifying.md)** — the design philosophy and the transform protocol.
- **[Reference](reference/core.md)** — every public function, by module.
- **[Examples](examples.md)** — a gallery of real, demanding computations.

!!! info "Building these docs"
    The site uses [MkDocs Material](https://squidfunk.github.io/mkdocs-material/).
    From the repository root:
    ```bash
    uv run --with mkdocs-material mkdocs serve   # live preview at localhost:8000
    uv run --with mkdocs-material mkdocs build   # static site into ./site
    ```
