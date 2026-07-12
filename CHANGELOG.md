# Changelog

All notable changes to this project. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); versioning is
[SemVer](https://semver.org/) — and pre-1.0, so anything may break.

## [Unreleased]

### Changed
- Renamed the package and context from `FormalCalc` to **`Calculemus`**.
- Sped up integral/sum verification: activate each side once and reuse for samples.
- **The tactic loop now serves the *search* for a derivation, not just its
  transcription** (look → recall a move → try → see what changed → retract):
  - A transform that leaves the expression unchanged (a rewrite whose left side
    matched nothing, a locator that missed) **records no step** — it can no
    longer masquerade as a verified line (`step::noop`).
  - `by[...]` **refuses a Refuted move**: the goal stays where it was, like an
    illegal move in a proof assistant, and the refusal message includes the
    numeric **counterexample** (sample point, both values). The functional
    layer (`step`) still records refuted steps for scripts.
  - `compute[...]` holds its argument and **inertizes** live `Integrate`/`Sum`/
    `Product`, so ordinary mathematical input works directly — no need to learn
    `dint`/`sum` before the first checkmark.
  - Numeric probes sample unconstrained variables with **both signs**, so a
    sign-dependent claim (e.g. `Sqrt[x^2] == x` with no assumptions) is refuted
    instead of slipping through a positive-only probe.
  - `evaluate` activates under the derivation's assumptions and strips
    `ConditionalExpression` conditions the chain already implies.
  - `ibp` takes boundary terms at infinite endpoints as **limits** under the
    derivation's assumptions (no more `0*E^(-Infinity u)` junk in results).
  - `abbreviate`/`let` replaces every occurrence of the named subexpression
    (a partial flat match no longer hides the one inside a power).

### Added
- README, LICENSE (MIT), ROADMAP, CHANGELOG.
- `assuming[cond]` — add an assumption mid-derivation (affects later steps only;
  contradictory additions rejected).
- `moves[]` — shape-directed discovery: which transforms apply to the current goal.
- `changed[]` — the current line with the parts that differ from the previous
  line highlighted.
- Refuted verification certificates carry a `"witness"` (sample point and both
  numeric values), surfaced in `step`/`by` messages.

## [0.1.0] — 2026-06-24

First cut: a verified relation-chain substrate and the modules built on it.

### Added
- **Core** — verified relation-chain substrate: equalities and inequalities
  composed into one running relation; live `Derivation` notebook panel.
- **Series** — graded truncation, weighted series expansion, verified `~` steps.
- **Matrix** — NCAlgebra-backed non-commutative algebra with random-matrix
  verification; quadratic forms under side relations; sym/antisym split.
- **Integral** — formal `Inactive[Integrate]` manipulation with quadrature
  verification; relation-aware checks.
- **Sums** — formal `Inactive[Sum]` manipulation; `Activate`/numeric verification;
  symbolic-`n` sums; gather (inverse of linearity); `reverseLimits`, `peelFirst`/
  `peelLast`.
- **Inequalities** — inequality system with assumption accumulation and
  contradiction rejection.
- **Two-sided (in)equations** — apply the same operation to both sides.
- **Gaussian domain pack** — log-density, complete-the-square, Gaussian integral.
- **Subexpressions** — addressing via `on` / `partOf` / `highlight` with natural
  locators.
- **Surface syntax** — tactic mode, verbs, `>op>` operator; abbreviations
  (`let w = expr`, work, restore); `claim` (unverified mid-derivation) and
  `caveats`.
- **Notebook assistance** — `SyntaxInformation`, argument-value completions,
  tooltips, argument hints.
- **Domain packs** separated from the general-purpose core.
- **Docs** — MkDocs Material site; examples gallery, including a tour-de-force
  Mellin computation (∫ x^{s-1}/(e^x−1) = Γ(s)ζ(s)).
