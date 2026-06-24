# Calculemus — examples gallery

Real computations done **semi-automatically**: you guide with a few
easy-to-read commands, the CAS performs the algebra, and every step is verified
(symbolically or by a numeric probe matched to the domain — random matrices,
quadrature, finite-sum evaluation).

Each file is self-contained and runnable:

```
wolframscript -file examples/01_perturbed_inverse.wl
```

(or, since `wolframscript` isn't on PATH here:
`"/Applications/Mathematica 2.app/Contents/MacOS/wolframscript" -file examples/01_perturbed_inverse.wl`)

Every example loads the package and `util.wl` (a small `showChain` printer), then
builds a `Derivation` by reassignment — `d = step[d, <move>, "note"]` — which reads
top-to-bottom and works in plain `.wl` scripts.

| File | Real computation | What you type vs. what the CAS does |
|------|------------------|-------------------------------------|
| `01_perturbed_inverse.wl` | `(S − V)⁻¹` to 2nd order — the inverse-covariance expansion `Σ⁻¹(t)` | You: "expand to order 2". CAS: builds the non-commutative Neumann series and checks the residual is `O(V³)` on random SPD `S`, random `V`. |
| `02_exponential_prefactor.wl` | `wᵀ(A+Aᵀ)w = 0` when `Aw = 0` — a vanishing term in the Gaussian-density-ratio prefactor | You: declare `Aw=0`, "expand", "apply". CAS: applies the relation and verifies vanishing by sampling random `w` and random `A` that *satisfy* `Aw=0`. |
| `03_gaussian_integral.wl` | complete-the-square, and `∫ e^{−a/2 x² + b x} dx` | You: "complete", "gaussian integral". CAS: produces the completed exponent and the closed form `√(2π/a) e^{b²/2a}`, checked by quadrature. |
| `04_integration_by_parts.wl` | `∫₀¹ x² eˣ dx` by parts (twice); a change of variables | You: pick `u` / the substitution. CAS: computes the antiderivative `v`, boundary terms, and the new limits — all quadrature-checked. |
| `05_bound_chain.wl` | a verified `=` then `≥` chain (a lower bound), mirroring the paper's `Ξ ≥ …` move | You: "expand", "drop the ≥0 remainder". CAS: composes the running relation and refuses a wrong-direction (upper-bound) claim. |
| `06_zeta_integral.wl` | `∫₀^∞ x³/(eˣ−1) dx = π⁴/15` (Bose–Einstein) in three steps | You: the one insight (geometric series). CAS: swaps sum↔integral, integrates each term, sums `6ζ(4)`, verifies each step symbolically. |
| `07_perturbation_root.wl` | regular perturbation: asymptotic root of `x = 1 + ε x³` (no closed form) | You: the equation + ansatz. CAS: expands, peels off the order equations, solves them; toolkit verifies the residual vanishes to `O(ε²)`. |
| `08_legendre_generating.wl` | read the Legendre polynomials off `1/√(1−2xt+t²)` | You: "expand to order 3 in t". CAS: the graded expansion of a nested square root; coefficients match `LegendreP[n,x]`. |
| `09_tactic_mode.wl` | the paper-like `compute` / `by` / `undo` workflow | a few computations built one verified line at a time, including a corrected misstep |
| `10_tour_de_force.wl` | **one long computation**: `∫₀^∞ xˢ⁻¹/(eˣ−1) dx = Γ(s)ζ(s)` (Mellin) | one quantity, nine verified lines — geometric series · Fubini · change of variables *inside the summand* · power split · pull constant · recognize Γ(s) · recognize ζ(s), with `s` symbolic |

## The pattern

1. `derive[expr, …]` — start from your expression; attach context (`Assumptions`,
   `Grading`/`GradingOrder`, `Relations`) **once**.
2. `step[d, move, "note"]` — name a move; the CAS performs it and verifies the
   asserted relation. Inferring moves (`changeVar[u, φ]`, `ibp[u]`,
   `dropHigherOrder[]`, `applyRel[]`) ask for the minimum and read context from
   the derivation; explicit forms (`changeVar[u, φ, {a,b}]`, `ibp[u, v]`, …)
   remain for full control.
3. The `Derivation` is the proof: a chain `e₀ R₁ e₁ R₂ …` with a ✓/✗ on each step
   and the composed start-to-finish relation.

Caveat seen in `04`: auto-solved change-of-variables limits assume a monotonic
substitution; for multivalued `x = φ(u)` pass explicit limits `{a, b}`.
