# Calculemus — architecture

*A Wolfram Language package for **verifiable, step-by-step formal manipulation** of
expressions, series, sums, integrals and — equally — **inequalities**. You drive
each transformation by hand; the package records the chain and checks every step.*

Scope and priorities come from [`../WISHLIST.md`](../WISHLIST.md). This document is
the structural plan; the wishlist is the feature backlog.

> Name `Calculemus` is a placeholder — trivial to rename now (it's one `BeginPackage`
> context + the paclet name). Say the word.

---

## 1. Design principles

1. **Formal, not numeric.** Nothing auto-evaluates. Integrals, sums, derivatives live as `Inactive` heads until *you* activate them. We manipulate form, never demand convergence.
2. **The chain is the proof.** A derivation is a sequence `e₀ R₁ e₁ R₂ e₂ …` where each `Rᵢ ∈ {=, ≤, ≥, <, >, ~}`. Equalities and inequalities are the *same* object — an equational derivation is just a chain whose relations are all `=`. This is §9.1 of the wishlist and the spine of the whole design.
3. **Verify every step, automatically.** Each step asserts a relation between consecutive expressions. The package checks it — symbolically under the derivation's assumptions, and with a numeric probe — and marks it ✓ / ✓ₙ / ✗ / ?. A flipped sign or a multiply-by-maybe-negative is caught the instant it happens. This is the user's non-negotiable "verifiable" requirement (§0.4).
4. **Perform first; verify underneath.** Transforms *do the algebra* — compute Jacobians, antiderivatives, series expansions, square-completions — and **infer what they can** so you specify the minimum: `changeVar[u, φ]` solves the new limits, `ibp[u]` computes `v`, `dropHigherOrder[]`/`applyRel[]` read the grading/relations off the derivation (set once). Verification is a silent safety net, not the product. The only thing the tool won't invent is a genuinely free *mathematical choice* (which way a bound goes, which substitution to try) — there you name the move and it executes it. Every inferring transform keeps an explicit-argument escape hatch, so generality is never sacrificed.
   - Mechanism: a transform is `expr -> result`, or `WithContext[(expr, ctx) -> result]` to read `Grading`/`GradingOrder`/`Relations`/`Assumptions` from the derivation.
5. **Lean on Mathematica; wrap only what's awkward.** Native `Expand`/`Factor`/`Simplify`/`Series`/`Reduce` are used directly. We build only the 🔴/🟡 items from the wishlist — graded truncation, the relation-chain, sign-direction bookkeeping, `Inactive`-rewrite packaging — never reinvent the 🟢 ones.
6. **Immutable & functional.** A `Derivation` is an inert value. `step` returns a *new* derivation. No hidden mutable state → replayable, branchable, diffable.
7. **General core vs domain packs.** The `Calculemus` core is general-purpose mathematics only — algebra, series, sums, integrals, non-commutative/matrix, bounds, verification. Anything *overly specific to one field* (probabilistic objects like Gaussian log-densities; named theorems like Slepian / Borell-TIS / Piterbarg) lives in a **separate context** (e.g. `Calculemus`Gaussian``) that the core does **not** load — you `Get` it explicitly on top. Litmus test: if a symbol encodes a domain *object or theorem* it's a pack; if it's a pure math *operation* (complete-the-square, the Gaussian integral, a quadratic form) it stays general. Domain packs only *provide* constructors/transforms; verification stays in the core (transforms route through `certify` automatically), so packs need no privileged access.

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

One context, `` Calculemus` ``. Files split along these boundaries as each module
lands — today the substrate and the first transform module exist; the rest are the
roadmap, not empty stubs.

| Layer | File | Wishlist § | Status |
|-------|------|-----------|--------|
| 0 | `Source/Core.wl` | §0.1 rewrite, §0.2 inert, §0.3 assumptions, §0.4 verify, §0.5 chain, relations | **built** |
| 1 | `Source/Bounds.wl` | §9 bounds: sign certs, drop-term, bound-in-place | **built (slice)** |
| 1 | `Source/Series.wl` | §4 graded truncation, multivariate o/O, formal-series arithmetic | **built** (`~` verification wired into `certify`) |
| 1 | `Source/Matrix.wl` | §3 noncommutative / matrix + §4.6 graded Neumann inverse (NCAlgebra backend) | **built** (random-matrix verification) |
| 1 | `Source/Sums.wl` | §5 reindex / split / Fubini / linearity | **built** (Activate + numeric verification) |
| 1 | `Source/Integral.wl` | §6 Inactive linearity / change-of-var / IBP / split / Fubini | **built** (numeric-quadrature verification) |
| 1 | `Source/Expr.wl` | §1 generic surgery, §2 commutative (scalar `completeSquare`; native wrappers) | **built** |
| 1 | `Source/Equation.wl` | two-sided (in)equation manipulation (§9.2 "both sides") | planned |
| 2 | `Source/Core.wl` | `derive` / `step` / accessors / rendering | **built** |
| **domain** | `Source/Domain/Gaussian.wl` | §8 probability-specific only: `gaussExp` (log-density), `prefactorExponent`; future Slepian/Borell-TIS/Piterbarg | **built** — **separate context `Calculemus`Gaussian``, NOT loaded by the core** |

The general math formerly in the Gaussian file now lives in the general core: scalar
`completeSquare` → `Expr.wl`; `quadForm`/`completeSquareMat` (symmetric quadratic-form
completion) → `Matrix.wl`; `gaussianIntegral` (a calculus identity) → `Integral.wl`.
| — | `Kernel/Calculemus.wl` | master loader + public usages | **built** |
| — | `Tests/*.wl` | assert-based self-checks per module | **built (core)** |

Native-heavy items (§2, §7.3) are used directly via Mathematica and wrapped only if a
real recurring pattern shows up.

---

## 5. Conventions

- **Public API** is declared (usage messages) in `Kernel/Calculemus.wl` before
  `Begin["\`Private\`"]`; implementation files are `Get` in private scope and attach
  definitions to those public symbols. Helpers stay in `` Calculemus`Private` ``.
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

1. ~~`Series.wl` — graded truncation + multivariate `o`/`O`~~ **done** — `certify` now verifies `~` steps via grading; scalar Neumann expansion reproduces the shadow of Lemma `Sigma-inverse`.
2. ~~`Matrix.wl` — NC Neumann inverse + random-matrix verification~~ **done** — wraps NCAlgebra (`tp`/`aj`/`inv`/`**`), adds graded `neumannInverse`/`expandInverse`, and verifies NC `=` steps (random matrices) and graded NC `~` steps (residual order probe). Reproduces the matrix `Σ⁻¹(t)` Neumann expansion.
   - *Done within §3:* symmetric/antisymmetric split (`symPart`/`antiPart`), and quadratic forms under side relations (`A₁w = 0`) — `applyRel` + verification that samples random matrices/vectors *satisfying* the relations (matrix `M·P` with `P` projecting off the annihilated vectors). The `wᵀ(A₁+A₁ᵀ)w = 0` vanishing is reproduced and verified.
   - *Next within §3:* combine Neumann + relations + prefactor algebra into the full "exponential prefactor" derivation from the paper; matrix (Loewner) ordering for NC inequalities.
3. ~~`Integral.wl` (§6) + `Sums.wl` (§5)~~ **done** — `Inactive[Integrate]`/`Inactive[Sum]` rewrites (linearity, change-of-var, IBP, split, reindex, Fubini, sum↔integral swap), verified by numeric quadrature / `Activate`+numeric.
4. ~~`Gaussian.wl` (§8) — log-density exponent, complete-the-square (scalar + matrix/exponent mean-shift), Gaussian integral normalization~~ **done**; verified via symmetric/SPD random sampling (`ncDeclareSym`).
   - *Not yet:* named inequalities (Slepian / Borell-TIS / Piterbarg). These are *asserted theorems*, not numerically checkable in our probe framework — they need a distinct "asserted-with-provenance" step status (a §0.5 feature), not algebraic verification. Deferred deliberately rather than faked as "Verified".
