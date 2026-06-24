# Formal-manipulation toolkit — manipulation wishlist

A hierarchical catalogue of the formula manipulations a working analyst /
mathematical physicist does *by hand*, that we want to do *by transformation*
in Mathematica — formally, step by step, verifiably, with no demand for
convergence or numeric evaluation.

Grounded in the recurring moves of arXiv:2401.05527 (vector-valued Gaussian
field extremes: matrix asymptotic expansions, graded truncation, quadratic
forms under side relations, Gaussian prefactor algebra, formal sums), then
generalized.

## Legend

**Mathematica coverage**
- 🟢 native — Mathematica does it well; toolkit needs at most a thin wrapper, or nothing.
- 🟡 awkward — possible natively but needs fiddly bespoke patterns *every time*; the toolkit's main value is packaging these once.
- 🔴 custom — needs genuine new machinery (no good native path).

**Priority** (for *this* user, from the paper)
- ★★★ spine — done constantly; the reason the toolkit exists.
- ★★ frequent.
- ★ occasional / nice-to-have.

---

## 0. Cross-cutting infrastructure
*Applies to every object below. This is what makes manipulation "manual but verifiable" rather than a black box.*

- **0.1 Targeted rewriting** — apply a transformation to *one chosen subexpression* / at a position, leaving the rest untouched. 🟡 ★★★
- **0.2 Inert representation** — hold integrals, sums, derivatives, products as inert objects (`Inactive`) so nothing auto-evaluates; activate selectively. 🟡 ★★★
- **0.3 Assumption & domain context** — carry constraints (`u → ∞`, `t > 0`, `β ∈ (0,2]`, matrix symmetric/PD) alongside an expression; guarantee fresh dummy variables/indices. 🟡 ★★
- **0.4 Verification certificates** — every transformation can emit a check: numeric spot-probe of `lhs − rhs`, symbolic `Simplify[lhs − rhs, assumptions]`, grading/order consistency, dimensional consistency. *This is the "verifiable" requirement.* 🔴 ★★★
- **0.5 Derivation log / provenance** — an ordered, replayable trail of (rule applied → result); reversibility check (apply transform then its inverse → identity). 🟡 ★★
- **0.6 Rule library + step display** — named reusable rules; pretty-printed before/after for each step (the notebook *is* the proof). 🟡 ★★

---

## 1. Generic expression surgery
*Structure-level moves on any expression.*

- **1.1 Substitution** — replace a variable, a subexpression, or a function head; back-substitution of an abbreviation. 🟢 ★★
- **1.2 Renaming** — α-rename bound variables / dummy summation & integration indices safely. 🟡 ★★
- **1.3 Restructuring** — regroup (associativity), distribute/factor structurally, flatten/nest. 🟢 ★
- **1.4 Collecting & sorting** — gather by a chosen variable/pattern; order terms by a custom key (e.g. by asymptotic weight). 🟡 ★★
- **1.5 Part extraction** — coefficient of a monomial, numerator/denominator, leading/trailing term, the "small" part of `A = A₀ + δ`. 🟢 ★★

---

## 2. Commutative algebra
*Mathematica's home turf — low build priority, mostly wrappers.*

- **2.1 Polynomial** — expand, factor, collect-by-variable, partial fractions, complete the square, resultant/elimination. 🟢 ★
- **2.2 Rational** — combine over common denominator, decompose, cancel under assumptions. 🟢 ★
- **2.3 Power / log / exp** — expand vs contract (`PowerExpand`, `ExpToTrig`…), branch-cut–aware manipulation. 🟡 ★
- **2.4 Trig / special functions** — product↔sum, functional equations, known expansions. 🟢 ★

---

## 3. Non-commutative & matrix / operator algebra
*Where symbols don't commute. NCAlgebra-backed; this is a real spine for the matrix expansions in the paper.*

- **3.1 Ordered products & commutators** — keep order, `[A,B]`/`{A,B}`, apply commutator identities. 🔴 ★★ *(NCAlgebra)*
- **3.2 Normal / canonical ordering** — reorder products by a chosen rule (Wick-type, ladder operators). 🔴 ★
- **3.3 Symbolic matrix algebra** — transpose, trace, inverse-as-symbol, symmetric/antisymmetric split `½(A±Aᵀ)`; `(A+Aᵀ)` patterns as in `B_{k,i}`. 🟡 ★★★
- **3.4 Bilinear / quadratic forms** — manipulate `xᵀ M x`, `bᵀ M b`; **simplify under linear side-relations** (`A₁w = 0 ⇒ whole term vanishes`), exploit symmetry to halve cross terms. 🔴 ★★★
- **3.5 Tensor / index algebra** — Einstein summation, symmetrization/antisymmetrization, index-set bookkeeping (`i,j ∈ ℱ`). 🟡 ★★
- **3.6 Operator exponentials** — `exp` of non-commuting operators, BCH, similarity transforms. 🔴 ★

---

## 4. Formal series & asymptotic expansion  — **THE SPINE**
*Series you manipulate, not series you truncate-and-evaluate. The single most-repeated, worst-served-natively part of your work.*

- **4.1 Formal series object** — an infinite/symbolic series as a first-class object (general-term `Sum`, held), distinct from finite `SeriesData`. 🔴 ★★
- **4.2 Expand to order** — Taylor / Laurent / Puiseux of a function to a stated order. 🟢 ★★
- **4.3 Custom multivariate graded truncation** — assign each generator `tᵢ` a weight `βᵢ` (fractional OK), drop every monomial above total weight `θ`. *(The `tᵢ^{βᵢ/2}` grading, the `o(Σ tᵢ^{βᵢ})` cutoff.)* 🔴 ★★★
- **4.4 Big-O / little-o bookkeeping** — `O[…]`/`o[…]` as algebraic objects with correct absorption/arithmetic, **multivariate** (`o(Σ tᵢ^{βᵢ})`), not just single-variable. 🔴 ★★★
- **4.5 Series arithmetic** — sum, Cauchy product, reciprocal, composition, reversion, `exp`/`log` of a series — to a given (graded) order. 🟡 ★★
- **4.6 Operator / matrix series** — Neumann / geometric series for `(Σ − E)⁻¹`, resolvent expansions, kept non-commutative and truncated by grading. *(Lemma "Sigma-inverse".)* 🔴 ★★★
- **4.7 Dominant balance & matching** — extract leading-order behaviour, inner/outer asymptotic matching, uniform-vs-pointwise tracking. 🔴 ★

---

## 5. Sums (finite & formal)
*High-value ergonomics: every one of these is a fiddly bespoke pattern natively.*

- **5.1 Reindex / shift** — change summation index, shift `k → k+1`. 🟡 ★★
- **5.2 Split / merge range** — split a sum at a point, peel off boundary terms, recombine. 🟡 ★★
- **5.3 Interchange order** — swap nested sums (Fubini for sums), swap with index sets `ℱ`. 🟡 ★★
- **5.4 Linearity** — pull out constants/factors independent of the index, split over `+`. 🟢 ★★
- **5.5 Telescoping & known closed forms** — telescope, apply geometric/binomial closed forms *as optional rewrites*. 🟡 ★
- **5.6 Indicator / Iverson algebra** — manipulate `𝟙_{i=j}`, `𝟙_{i,j∈ℱ}`; case-split on index conditions. 🔴 ★★
- **5.7 Symmetrization** — symmetrize a summand over index permutations; fold `i,j` cross terms. 🟡 ★

---

## 6. Integrals (formal, no evaluation)  — `Inactive`-based
*Hold the integral inert and rewrite it. Real but lower-frequency than series for you.*

- **6.1 Linearity** — pull out constants, split over sums. 🟡 ★★
- **6.2 Change of variables** — substitution with Jacobian; affine/scaling substitutions for asymptotics (the `u`-scaling). 🟡 ★★
- **6.3 Integration by parts** — pick the part to differentiate; track boundary term. 🟡 ★★
- **6.4 Differentiate under the integral** — Leibniz rule, including moving-boundary terms. 🟡 ★
- **6.5 Domain surgery** — split / merge domains, reverse limits, restrict to a region. 🟡 ★★
- **6.6 Interchange order** — swap nested integrals (Fubini), **swap sum ↔ integral**. 🟡 ★★
- **6.7 Convolution & product** — manipulate convolutions, products of integrals. 🟡 ★
- **6.8 Gaussian normalization** — recognize/normalize a Gaussian integral to standard form (feeds §8). 🔴 ★★

---

## 7. Limits & global asymptotics
- **7.1 Formal limit** — limit as inert/symbolic, with assumptions. 🟡 ★
- **7.2 Asymptotic order relations** — `~`, `≪`, `O`/`o`-dominance as first-class chainable relations. *See §9.9 — lives with inequalities.* 🔴 ★★
- **7.3 L'Hôpital / leading-term** — formal indeterminate-form rewrites. 🟢 ★
- **7.4 Scaling-exponent extraction** — pull the power of `u` out of an asymptotic expression. 🟡 ★★

---

## 8. Probability layer (domain pack)
*Built on §2–§7. Specific to your work, but reusable across the field.*

- **8.1 Gaussian log-density algebra** — manipulate `ln φ_Σ(·)`, ratios of densities (the "exponential prefactor"), **complete the square in the exponent**. 🔴 ★★★
- **8.2 Covariance matrix algebra** — `Σ(t)`, `R(t,s)`, inverse expansions, generalized variance `min_{x≥b} xᵀΣ⁻¹x`. 🔴 ★★★
- **8.3 Change of measure / mean-shift** — Girsanov-style formal shifts, recentering. 🔴 ★
- **8.4 Conditioning / marginalization** — as formal integral operations over densities. 🔴 ★
- **8.5 Moments / cumulants** — moment↔cumulant rewrites, Wick/Isserlis for Gaussians. 🔴 ★

---

## 9. Bounds, inequalities & order relations  — **SPINE**
*Asymptotic analysis* is *inequality manipulation. The error-prone part by hand is
direction bookkeeping (a flipped sign, a multiply by a maybe-negative factor); the
toolkit's job is to carry the chain and **verify every step preserves direction** (§0.4).*

- **9.1 Inequality chain as a first-class object** — maintain `a ≤ b ≤ c …` (mixed `<, ≤, =, ~`), auto-compose transitively to the end-to-end bound; the chain *is* the proof. 🔴 ★★★
- **9.2 Monotone operation on both sides** — add/subtract; multiply by a quantity of known sign (auto-flip on negative); apply a monotone function (`exp`, `log`, `√`, square-on-nonneg); integrate / sum both sides — direction tracked & verified. 🔴 ★★★
- **9.3 Bound a subterm in place** — replace a subexpression by a larger/smaller one with the *correct induced direction* given surrounding monotonicity & sign (enlarge numerator ↑ vs denominator ↓; position-aware). 🔴 ★★★
- **9.4 Drop / add terms** — drop a nonneg term to get `≤` (add for `≥`); the `underbracket{·}_{≥0}` moves. 🟡 ★★★
- **9.5 Named inequalities as directional rewrites** — triangle, Cauchy–Schwarz, AM–GM, Jensen, Hölder, Young, union bound, Markov/Chebyshev — applied with side-conditions & direction. Domain-specific ones (Slepian, Borell-TIS, Piterbarg) registered alongside the §8 pack. 🔴 ★★
- **9.6 Relaxation / tightening** — `≤ max`, `≥ min`, `sup`/`inf`; enlarge integration domain (nonneg integrand); indicator bounds `𝟙_A ≤ 1`. 🟡 ★★
- **9.7 Sign & positivity certificates** — prove a term `≥ 0` (a square, a sum of nonnegatives, a PD quadratic form / PD covariance), feeding 9.3–9.4. 🔴 ★★★
- **9.8 Squeeze / two-sided** — combine `≤` and `≥` into `~` or `=`; sandwich arguments. 🔴 ★★
- **9.9 Asymptotic order relations** — `~`, `≲` (≤ up to constant), `o`, `O`, `≪`; chain them and interconvert with `≤` (the `prefactor-inequality`). 🔴 ★★★
- **9.10 Piecewise / case-split bounding** — partition the domain, bound each piece, recombine (the log-layer and double-sum bounds). 🔴 ★★

---

## Build order (minimal viable path)

The spine is §9 + §4 sitting on the §0.4 verifier; §3.3–3.4 and §8.1–8.2 are the
matrix/Gaussian muscle on top.

1. **§0.4 verification certificate** + **§0.2 inert hold** — the substrate; everything else is checkable from day one.
2. **§9.1–9.2 inequality chain + monotone-ops** + **§9.7 sign certificates** — the directional substrate; pairs naturally with the verifier (a step that flips direction fails its check immediately).
3. **§4.3 graded truncation** + **§4.4 multivariate o/O** — the most-repeated expansion move; interoperates with §9.9 order relations. Validate against the `Σ⁻¹(t)` Neumann expansion (Lemma "Sigma-inverse").
4. **§4.6 Neumann series** + **§3.3–3.4 matrix / quadratic-form algebra** (NCAlgebra) + **§9.3–9.4 bound-in-place / drop-terms** + **§9.10 case-split** — reproduce the "exponential prefactor" derivation *and* its inequality `prefactor-inequality`.
5. **§5 sum surgery** + **§6 Inactive integral moves** — broaden to the rest of the proof machinery.
6. **§8 probability pack** — fold recurring Gaussian moves and the named §9.5 inequalities (Slepian / Borell-TIS / Piterbarg) into operators.

Lower-priority / native-heavy (§2, §7.3) we lean on Mathematica directly and only
wrap if a real pattern recurs.
