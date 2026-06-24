# Reference — Sums

Formal manipulation of sums held as `Inactive[Sum]` (`Source/Sums.wl`). Pure
rewrites; finite sums `Activate` to explicit term sums, so `Simplify` proves each
equality, with a random-parameter numeric fallback.

## Constructor

```mathematica
sum[f, {k, a, b}]   (* Inactive[Sum][f, {k, a, b}] *)
```

## `sumLinearity`

Split over addends and pull out factors free of the index.

```mathematica
derive[sum[c k + k^2, {k, 0, 5}]] // step[sumLinearity]
(* c Sum k + Sum k^2 *)
```

## `shiftIndex`

```mathematica
shiftIndex[c]   (* reindex k -> k - c, shifting the bounds by c *)
```

```mathematica
derive[sum[k^2, {k, 0, 3}]] // step[shiftIndex[2]]
(* Sum_{k=2}^{5} (k-2)^2  -- same value, verified *)
```

## `splitSum`

```mathematica
splitSum[m]   (* split the range at an interior point m *)
```

## `peelFirst` / `peelLast`

Split off a boundary term: `Σ_{k=a}^b f = f(a) + Σ_{k=a+1}^b f`.

```mathematica
derive[sum[k^2, {k, 1, n}]] // step[peelFirst]   (* 1 + Sum_{k=2}^n k^2 *)
```

## `swapSum`

```mathematica
swapSum   (* interchange two nested sums (Fubini), independent bounds *)
```

```mathematica
derive[Inactive[Sum][Inactive[Sum][i j, {j, 0, 3}], {i, 0, 2}]] // step[swapSum]
```

## `gather` — the inverse of linearity

Pull constant factors back inside and combine sums over the same range into one:

```mathematica
derive[c sum[k, {k, 0, 5}] + sum[k^2, {k, 0, 5}]] // step[gather]
(* Sum_{k=0}^5 (c k + k^2) *)
```

(`gather` works for held integrals too — see [Integrals](integrals.md).)

## Symbolic dimension `n`

Sums over a symbolic range `1..n` (a variable, not a fixed number) — including
double sums `Σ_{i,j=1}^n` — are manipulated structurally by all the rules above,
and **verified by testing several concrete dimensions** (`n → 2, 3, 4, …`, which
makes the range finite). A wrong move is caught at those dimensions.

```mathematica
derive[sum[k^2, {k, 1, n}]] // step[shiftIndex[1]]                 (* verified *)
derive[Inactive[Sum][Inactive[Sum][i j, {j, 1, n}], {i, 1, n}]] // step[swapSum]
```

!!! tip "Sum ↔ integral"
    To swap a sum with an integral, use [`swapSumIntegral`](integrals.md#swapsumintegral)
    from the Integral module.
