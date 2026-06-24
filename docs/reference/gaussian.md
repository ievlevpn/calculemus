# Reference — Gaussian pack (domain)

!!! warning "A domain pack, not the core"
    These symbols live in the **separate** context `` Calculemus`Gaussian` ``,
    which the general core does **not** load. Bring it in explicitly:
    ```mathematica
    Get[".../Source/Domain/Gaussian.wl"];
    ```
    See [Core vs domain packs](../concepts/domain-packs.md).

This pack holds objects *specific to Gaussian / extreme-value probability*. The
general math it once mixed in now lives in the core
([`completeSquare`](algebra.md), [`completeSquareMat`/`quadForm`](matrix.md),
[`gaussianIntegral`](integrals.md)).

## `gaussExp`

```mathematica
gaussExp[x, s]   (* -1/2 tp[x] ** inv[s] ** x *)
```

The exponent of a centered Gaussian log-density with covariance `s` (NC-aware, so
`x` is a vector and `s` a matrix).

## `prefactorExponent`

```mathematica
prefactorExponent[x1, s1, x2, s2]   (* gaussExp[x1, s1] - gaussExp[x2, s2] *)
```

The exponent of a Gaussian log-density **ratio** — the core of the "exponential
prefactor" in high-exceedance asymptotics.

```mathematica
Get[".../Source/Domain/Gaussian.wl"];
ncDeclareSym[cov]; ncDeclareVec[x, y];
prefactorExponent[x, cov, y, cov]
(* -1/2 tp[x]**inv[cov]**x + 1/2 tp[y]**inv[cov]**y *)
```

These constructors flow through the core's verification automatically when used in
a `step` (they produce ordinary non-commutative expressions).

## Roadmap

The **named process inequalities** — Slepian, Borell–TIS, Piterbarg — belong here.
They are *asserted theorems*, not numerically checkable by the probes, so they
await an honest "asserted, by theorem X" provenance status rather than being
presented as `Verified`. They will land in this pack, never in the general core.
