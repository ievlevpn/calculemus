# Roadmap

High-level direction. The full, fine-grained catalogue of desired manipulations
(with native/awkward/custom and priority ratings) lives in
[WISHLIST.md](WISHLIST.md) — this file is the summary of what's done and what's next.

Priorities are *for this project's actual use* — large asymptotic computations in
mathematical physics (the moves of arXiv:2401.05527) — not general coverage.

## Done (0.1.0)

- **Verified relation-chain substrate** — equalities *and* inequalities composed
  into one running relation; the chain is the proof.
- **Performing transforms** — Jacobians, antiderivatives, series expansions,
  square completions; transforms infer what they can.
- **Verification** — symbolic `Simplify` plus domain-matched numeric probes
  (random matrices, quadrature, finite-sum evaluation).
- **Modules** — general algebra, series/asymptotics, matrix/non-commutative,
  formal integrals, formal sums, inequalities, two-sided (in)equations, Gaussian
  domain pack.
- **Surface syntax** — tactic mode, verbs, `>op>` operator, subexpression
  addressing, abbreviations (`let`), notebook autocomplete & tooltips.

## Next

- **Coverage of the spine moves** (★★★ in the wishlist) that are still awkward —
  targeted rewriting ergonomics, graded truncation edge cases, quadratic forms
  under side relations.
- **Better failure messages** — when a step won't verify, say *why* (which probe,
  what residual) instead of a bare `False`.
- **Reversibility / provenance** — apply-then-invert identity checks; replayable
  derivation logs.

## Later / maybe

- Branch-cut–aware power/log/exp manipulation.
- Wider special-function functional equations and known expansions.
- Additional domain packs beyond Gaussian, as concrete computations demand them.

Scope is demand-driven: machinery gets built when a real computation needs it,
not speculatively. See [WISHLIST.md](WISHLIST.md) for the detailed backlog.
