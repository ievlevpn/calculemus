# FormalCalc — architecture

*A Wolfram Language package for **verifiable, step-by-step formal manipulation** of
expressions, series, sums, integrals and — equally — **inequalities**. You drive
each transformation by hand; the package records the chain and checks every step.*

Scope and priorities come from [`../WISHLIST.md`](../WISHLIST.md). This document is
the structural plan; the wishlist is the feature backlog.

> Name `FormalCalc` is a placeholder — trivial to rename now (it's one `BeginPackage`
> context + the paclet name). Say the word.

---

## 1. Design principles

1. **Formal, not numeric.** Nothing auto-evaluates. Integrals, sums, derivatives live as `Inactive` heads until *you* activate them. We manipulate form, never demand convergence.
2. **The chain is the proof.** A derivation is a sequence `e₀ R₁ e₁ R₂ e₂ …` where each `Rᵢ ∈ {=, ≤, ≥, <, >, ~}`. Equalities and inequalities are the *same* object — an equational derivation is just a chain whose relations are all `=`. This is §9.1 of the wishlist and the spine of the whole design.
3. **Verify every step, automatically.** Each step asserts a relation between consecutive expressions. The package checks it — symbolically under the derivation's assumptions, and with a numeric probe — and marks it ✓ / ✓ₙ / ✗ / ?. A flipped sign or a multiply-by-maybe-negative is caught the instant it happens. This is the user's non-negotiable "verifiable" requirement (§0.4).
4. **The tool verifies your claim; it does not guess your intent.** You assert "this step is a `≤`"; the package confirms or refutes it. We do *not* try to derive monotonicity or decide which direction a bound goes — that's your mathematical judgment. This makes the tool both lazier and more honest, and keeps you in the driver's seat (your stated workflow).
5. **Lean on Mathematica; wrap only what's awkward.** Native `Expand`/`Factor`/`Simplify`/`Series`/`Reduce` are used directly. We build only the 🔴/🟡 items from the wishlist — graded truncation, the relation-chain, sign-direction bookkeeping, `Inactive`-rewrite packaging — never reinvent the 🟢 ones.
6. **Immutable & functional.** A `Derivation` is an inert value. `step` returns a *new* derivation. No hidden mutable state → replayable, branchable, diffable.

---

## 2. Two-layer model

The single most important structural decision. The math and the bookkeeping are
decoupled.

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 2 — DERIVATION  (thin, stateful-by-value orchestration) │
│   derive[…]  ·  step[…]  ·  the relation-chain  ·  rendering   │
│   Records each step + runs the verifier. Optional sugar.       │
└───────────────────────────┬───────────────────────────────────┘
                            │ calls
┌───────────────────────────▼───────────────────────────────────┐
│ Layer 1 — TRANSFORMS  (pure, stateless functions on exprs)     │
│   expr ↦ expr            (equality-preserving moves)           │
│   expr ↦ Yields[expr, relation, note]   (relation-changing)    │
│   Usable directly, testable in isolation. ALL the math lives   │
│   here. Inactive-based, assumption-aware.                      │
└───────────────────────────┬───────────────────────────────────┘
                            │ uses
┌───────────────────────────▼───────────────────────────────────┐
│ Layer 0 — CORE substrate                                       │
│   Relations algebra · Verification · Assumptions · Rewrite     │
└────────────────────────────────────────────────────────────────┘
```

- A **transform** is just a function of the current expression. It returns either a bare expression (the step is an equality, `=`) or `Yields[newExpr, relation, note]` when it changes the relation (a bound). That's the entire contract — no transform objects, no registry. Lazy users compose transforms directly and never touch Layer 2.
- A **step** applies one transform, asks the verifier whether the asserted relation actually holds, appends a record, and returns the new derivation.
- Because transforms are plain functions, every math module is unit-testable without the derivation machinery, and the derivation machinery is testable with trivial stub transforms.

### Why a single-quantity chain (not two-sided equations)

The dominant pattern in asymptotic analysis — and throughout the source paper — is
**bounding one quantity** through a chain of relations: `P{…} ≤ … ≤ final bound`.
So a `Derivation` tracks *one evolving expression* and its relation back to the
start. "Apply f to both sides" / "multiply both sides" is a *different* object —
a two-sided (in)equation — useful for solving rather than bounding. It's deliberately
**not** in the core; it's a planned sibling (`Equation`) so the common case stays simple.

---

## 3. Core objects

### `Derivation[<| "start", "assumptions", "steps" |>]`
Inert association-wrapper. `steps` is a list of
`<| "result", "relation", "note", "cert" |>`. Accessors: `result`, `relationOf`
(transitive composition of all step relations), `assumptionsOf`, `stepsOf`,
`verifiedQ`. Renders in a notebook as a framed, aligned chain with ✓/✗ marks
(`MakeBoxes`); operate on it via the accessors, not its display.

### Relations
A small algebra over `{Equal, LessEqual, GreaterEqual, Less, Greater, AsymEqual}`:
- `composeRelation[r₁, r₂]` — transitive composition (`≤∘≤ = ≤`, `<∘≤ = <`, `=∘r = r`, `~∘~ = ~`; mixing `≤` with `≥` ⇒ `$Failed` + message).
- `flipRelation[r]` — direction reversal for negative multipliers.

### Verification — `certify[before, after, relation, assumptions]`
Returns `<| "relation", "symbolic", "numeric", "status" |>`.
- **symbolic**: `Simplify[before R after, assumptions]` → `True | False | Unknown`.
- **numeric**: probe at sample points satisfying the assumptions (`FindInstance` seed + jitter), test the relation with tolerance → `True | False | Unknown`.
- **status**: `Refuted` (either check disproves) ▸ `Verified` (symbolic proves) ▸ `NumericOnly` (only the probe supports it) ▸ `Unverified` (no evidence either way, e.g. `~`).

`AsymEqual` (`~`) is honestly marked `Unverified` for now — rigorous checking needs the
graded-order machinery (`e ~ f ⟺ e−f = o(scale)`), which arrives with §4. The numeric
matrix-probe (substitute random matrices to check non-commutative identities) is the
natural extension once §3 lands.

---

## 4. Module map  (wishlist § → file → status)

One context, `` FormalCalc` ``. Files split along these boundaries as each module
lands — today the substrate and the first transform module exist; the rest are the
roadmap, not empty stubs.

| Layer | File | Wishlist § | Status |
|-------|------|-----------|--------|
| 0 | `Source/Core.wl` | §0.1 rewrite, §0.2 inert, §0.3 assumptions, §0.4 verify, §0.5 chain, relations | **built** |
| 1 | `Source/Bounds.wl` | §9 bounds: sign certs, drop-term, bound-in-place | **built (slice)** |
| 1 | `Source/Series.wl` | §4 graded truncation, multivariate o/O, formal-series arithmetic | next |
| 1 | `Source/Matrix.wl` | §3 noncommutative / matrix / quadratic forms (NCAlgebra bridge) | planned |
| 1 | `Source/Sums.wl` | §5 reindex / split / Fubini / Iverson | planned |
| 1 | `Source/Integral.wl` | §6 Inactive IBP / change-of-var / Leibniz / Fubini | planned |
| 1 | `Source/Expr.wl` | §1 generic surgery, §2 commutative (mostly native wrappers) | planned |
| 1 | `Source/Equation.wl` | two-sided (in)equation manipulation (§9.2 "both sides") | planned |
| 2 | `Source/Core.wl` | `derive` / `step` / accessors / rendering | **built** |
| domain | `Source/Gaussian.wl` | §8 Gaussian log-density, covariance, Slepian/Borell-TIS/Piterbarg | planned |
| — | `Kernel/FormalCalc.wl` | master loader + public usages | **built** |
| — | `Tests/*.wl` | assert-based self-checks per module | **built (core)** |

Native-heavy items (§2, §7.3) are used directly via Mathematica and wrapped only if a
real recurring pattern shows up.

---

## 5. Conventions

- **Public API** is declared (usage messages) in `Kernel/FormalCalc.wl` before
  `Begin["\`Private\`"]`; implementation files are `Get` in private scope and attach
  definitions to those public symbols. Helpers stay in `` FormalCalc`Private` ``.
- **Curried `step`** for `//`-chaining — the manual workflow reads top-to-bottom:
  ```mathematica
  derive[(a + b)^2, Assumptions -> True]
    // step[rewrite[(a + b)^2 -> a^2 + 2 a b + b^2]]   (* = , verified *)
    // step[dropTerm[a^2], "drop a^2 >= 0"]            (* >= , verified *)
  ```
- **`Yields[expr, relation, note]`** is the only protocol a transform needs to speak to
  declare a non-equality step. Equality is the default (bare return).
- **Assumptions** ride with the derivation (`Assumptions -> …`, a boolean or list),
  independent of global `$Assumptions`, and are passed to every `certify` call.

---

## 6. Current slice (this commit)

Build-order steps 1–2 from the wishlist: the **verified relation-chain substrate**.

- `Core.wl` — relations algebra, `certify` (symbolic + numeric), `derive`/`step`/accessors, targeted rewrite `at`, `rewrite`, notebook rendering.
- `Bounds.wl` — `signOf` (sign/positivity certificate, §9.7), `dropTerm` (§9.4), `boundBy`/`boundSub` (§9.3/9.6).
- `Tests/CoreTests.wl` — proves: relation composition; a verified equality derivation; a verified inequality chain; a **refuted** wrong-direction bound is caught; sign certificates. Run headless via `wolframscript`.

This is the smallest thing that demonstrates the two headline requirements end to end:
**step-by-step manual transformation** + **automatic verification** of both equalities
and inequalities.

## 7. Roadmap (after this slice)

1. **`Series.wl` — graded truncation + multivariate `o`/`O`** (§4.3/4.4): the equality/`~` spine. Validate against the `Σ⁻¹(t)` Neumann expansion. Lets `certify` finally verify `~` steps.
2. **`Matrix.wl`** (§3.3/3.4 + §4.6): Neumann inverse, quadratic forms under side relations; matrix numeric-probe verification. Reproduce the "exponential prefactor".
3. **`Sums.wl` / `Integral.wl`** (§5/§6): the `Inactive`-rewrite packaging.
4. **`Gaussian.wl`** (§8): fold recurring Gaussian moves + named inequalities (Slepian / Borell-TIS / Piterbarg) into operators.
