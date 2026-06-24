# FormalCalc

**Verifiable, step-by-step formal manipulation in Mathematica.**

FormalCalc is a Wolfram Language toolkit for doing complicated algebraic and
analytic computations the way you'd do them on paper — one transformation at a
time — except the CAS *performs* each move and *checks* it for you. It targets
the kind of work where you don't need numeric evaluation, only correct formal
manipulation: series and asymptotic expansions, formal integrals and sums,
non-commutative / matrix algebra, and chains of inequalities.

!!! quote "The idea in one line"
    You guide the computation with short, readable commands; the CAS does the
    algebra and verifies every step; the resulting **derivation is the proof**.

## A first taste

A genuinely hard improper integral, in three guided steps — each verified:

```mathematica
Get["/path/to/mathematica-toolkit/Kernel/FormalCalc.wl"];

d = derive[Inactive[Integrate][x^3/(E^x - 1), {x, 0, Infinity}], Assumptions -> x > 0];
d = step[d, rewrite[1/(E^x - 1) -> Inactive[Sum][E^(-k x), {k, 1, Infinity}]],
     "geometric series"];
d = step[d, swapSumIntegral, "swap the sum and the integral"];
d = step[d, Activate,        "integrate each term and sum 6 zeta(4)"];

result[d]      (* Pi^4/15 *)
verifiedQ[d]   (* True    *)
```

You supplied the one insight (the geometric series). The CAS swapped the sum and
integral, integrated each term, summed the series, and verified each step
symbolically.

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
