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

## `swapSum`

```mathematica
swapSum   (* interchange two nested sums (Fubini), independent bounds *)
```

```mathematica
derive[Inactive[Sum][Inactive[Sum][i j, {j, 0, 3}], {i, 0, 2}]] // step[swapSum]
```

!!! tip "Sum ↔ integral"
    To swap a sum with an integral, use [`swapSumIntegral`](integrals.md#swapsumintegral)
    from the Integral module.
