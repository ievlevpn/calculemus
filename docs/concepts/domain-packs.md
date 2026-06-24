# Core vs domain packs

Calculemus draws a hard line between **general-purpose mathematics** and material
**overly specific to one field**.

- The **`` Calculemus` `` core** is general math only: relations & verification,
  general algebra, series & asymptotics, non-commutative / matrix algebra, formal
  integrals and sums, bounds.
- A **domain pack** lives in its own context (e.g. `` Calculemus`Gaussian` ``) that
  the core does **not** load. You bring it in explicitly, on top of the core.

```mathematica
Get[".../Kernel/Calculemus.wl"];          (* general toolkit *)
Get[".../Source/Domain/Gaussian.wl"];     (* Calculemus`Gaussian`, on top *)
```

## The litmus test

> If a symbol encodes a domain **object or theorem**, it belongs in a pack.
> If it is a pure mathematical **operation**, it stays in the general core.

Worked through for the Gaussian material:

| Symbol | Verdict | Home |
|--------|---------|------|
| `completeSquare` (scalar) | general algebra | core — `Expr` |
| `quadForm`, `completeSquareMat` | general matrix algebra | core — `Matrix` |
| `gaussianIntegral` | a general calculus identity | core — `Integral` |
| `gaussExp`, `prefactorExponent` | **probabilistic objects** (log-densities) | pack — `Calculemus`Gaussian` |
| Slepian / Borell–TIS / Piterbarg | **named process theorems** | pack (future) |

You can confirm the separation at runtime:

```mathematica
Context[gaussExp]   (* "Calculemus`Gaussian`"  -- not in the core *)
```

## Why packs need no special access

A pack only **provides** constructors and transforms. Verification stays in the
core and runs automatically: when a pack's transform produces, say, a
non-commutative expression, it routes through the core's `certify` exactly like
any other transform. So a pack is just a thin library of domain-flavoured moves —
it inherits the whole verification machinery for free.

This is also why **named inequalities are deferred rather than faked**: a theorem
like Borell–TIS is an *asserted* fact about Gaussian processes, not something the
numeric probes can check. It needs an honest "asserted, by theorem X" provenance
status — a future feature — and it will live in the Gaussian pack, never touching
the general library.

!!! tip "Writing your own pack"
    A pack is an ordinary package that depends on the core:
    ```mathematica
    BeginPackage["Calculemus`MyField`", {"Calculemus`", "NonCommutativeMultiply`"}];
    myMove::usage = "...";
    Begin["`Private`"];
    myMove[args__] := (* return an expression or Yields[...] *);
    End[]; EndPackage[];
    ```
    Load the core, then `Get` your pack. Its transforms work in `step` and are
    verified by the core with no extra wiring.
