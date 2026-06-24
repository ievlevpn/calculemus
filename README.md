# Calculemus

> ⚠️ **Disclaimer.** This is a **personal research project**, pre-1.0,
> experimental, and provided **as-is** with no warranty. It grew out of an old
> personal collection of Mathematica scripts and is **not a proof assistant** —
> verification is symbolic plus numeric spot-probes, which catches mistakes in
> practice but is **not a formal guarantee**. APIs and notation **will change
> without notice**. Check anything that matters.

**Verifiable, step-by-step formal manipulation in Mathematica.**

> *"...when there are disputes among persons, we can simply say:
> **Calculemus** — Let us calculate — without further ado, to see who is right."*
> — Gottfried Wilhelm Leibniz

Calculemus is a Mathematica toolkit for the long computations you'd normally do on
paper — page after page — except you do them **in a notebook**, one cell at a time,
and the CAS *performs* each move and *checks* it. One unnoticed slip on page 3 no
longer quietly ruins everything after it. It targets work where you want correct
**formal** manipulation, not numeric evaluation: series and asymptotic expansions,
formal integrals and sums, non-commutative / matrix algebra, and chains of
inequalities.

In each notebook cell you name a move; the CAS does the algebra and verifies it;
the cell shows the derivation so far, and that **derivation is the proof**.

![A live Derivation panel: the Mellin computation of ∫₀^∞ x^{s-1}/(eˣ−1) dx = Γ(s)ζ(s), each step marked verified, with one step resting on an unverified claim surfaced by caveats[].](docs/assets/derivation-panel.png)

## A first taste

Load the package and evaluate these as **separate cells** (`⇧↵`) — a genuinely
hard improper integral, one verified line per cell:

```mathematica
Get["/path/to/mathematica-toolkit/Kernel/Calculemus.wl"]   (* once, at the top *)

compute[ dint[x^3/(E^x - 1), {x, 0, Infinity}], Assumptions -> x > 0 ]
by[ rewrite[1/(E^x - 1) -> sum[E^(-k x), {k, 1, Infinity}]], "geometric series" ]
by[ fubini ]
by[ evaluate ]

result[goal[]]      (* Pi^4/15 *)
verifiedQ[goal[]]   (* True    *)
```

You supplied the one insight (the geometric series); the CAS swapped the sum and
integral, integrated each term, summed the series, and **verified every line**.

## Documentation

Full docs (MkDocs Material) live in [`docs/`](docs/index.md). Build them with:

```bash
uv run --with mkdocs-material mkdocs serve   # live preview at localhost:8000
```

Start with **[Getting started](docs/getting-started.md)**, then browse the
**[examples gallery](examples/)** for real, demanding computations.

## Status

A **personal research project**, written by one person for their own
mathematical-physics work (the recurring moves of large asymptotic computations).
It grew out of an old personal collection of Mathematica scripts accumulated for
the same purpose, gradually consolidated into a coherent toolkit. See the
disclaimer at the top — no support, no stability promises, use at your own risk.

## See also

- [ROADMAP.md](ROADMAP.md) — where this is going (full catalogue in [WISHLIST.md](WISHLIST.md)).
- [CHANGELOG.md](CHANGELOG.md) — what's changed.
- [LICENSE](LICENSE) — MIT.
