# Reference — Integrals

Formal manipulation of integrals held as `Inactive[Integrate]`
(`Source/Integral.wl`). Nothing is evaluated; transforms are pure rewrites,
verified by **numeric quadrature** (substitute random parameters, map
`Inactive[Integrate]`→`NIntegrate`, compare) plus a time-bounded symbolic
`Activate` check.

## Constructors

```mathematica
dint[f, {x, a, b}]   (* definite:   Inactive[Integrate][f, {x, a, b}] *)
iint[f, x]           (* indefinite: Inactive[Integrate][f, x]         *)
```

## `linearity`

Split held integrals over sums and pull out factors free of the integration
variable.

```mathematica
derive[dint[a x + b x^2, {x, 0, 1}]] // step[linearity]
(* a Int x + b Int x^2 *)
```

## `changeVar`

```mathematica
changeVar[u, phi]            (* x = phi(u): Jacobian inserted, new limits SOLVED *)
changeVar[u, phi, {ua, ub}]  (* explicit new limits                              *)
```

```mathematica
derive[dint[Exp[2 x], {x, 0, 1}]] // step[changeVar[u, u/2]]
(* Int_0^2 Exp[u]/2 *)
```

!!! warning "Monotonic substitutions"
    Auto-solved limits assume a monotonic `x = phi(u)`. For a multivalued `phi`
    (e.g. `x = u^2`) pass explicit limits `{ua, ub}`.

## `ibp`

```mathematica
ibp[u]      (* the antiderivative v of the rest is COMPUTED for you *)
ibp[u, v]   (* explicit v; the integrand must equal u * D[v, x]      *)
```

```mathematica
derive[dint[x^2 Exp[x], {x, 0, 1}]] // step[ibp[x^2]]
(* E - Int 2 x Exp[x]  -- boundary term and the (held) remainder *)
```

## `splitDomain`

```mathematica
splitDomain[c]   (* Int_a^b -> Int_a^c + Int_c^b *)
```

## `swapSumIntegral`

Interchange a held sum and integral (either order). A multiplicative factor free
of the summation index is carried through:

```mathematica
derive[Inactive[Integrate][x^3 Inactive[Sum][E^(-k x), {k, 1, Infinity}], {x, 0, Infinity}]]
  // step[swapSumIntegral]
(* Sum_k Int x^3 E^(-k x) *)
```

## `gaussianIntegral`

A general definite-integral identity:

\[
\int_{-\infty}^{\infty} e^{k x^2 + m x + c_0}\,dx = \sqrt{-\pi/k}\;e^{\,c_0 - m^2/(4k)}, \quad k < 0.
\]

```mathematica
derive[Inactive[Integrate][Exp[-(a/2) x^2 + b x], {x, -Infinity, Infinity}], Assumptions -> a > 0]
  // step[gaussianIntegral]
(* Sqrt[2 Pi/a] Exp[b^2/(2 a)] *)
```

!!! tip "Evaluating elementary pieces"
    To finish a chain by actually computing a held integral, use the built-in
    `Activate` as a transform: `step[d, Activate]`. It is verified like any step.
