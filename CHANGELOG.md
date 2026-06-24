# Changelog

All notable changes to this project. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); versioning is
[SemVer](https://semver.org/) — and pre-1.0, so anything may break.

## [Unreleased]

### Changed
- Renamed the package and context from `FormalCalc` to **`Calculemus`**.
- Sped up integral/sum verification: activate each side once and reuse for samples.

### Added
- README, LICENSE (MIT), ROADMAP, CHANGELOG.

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
