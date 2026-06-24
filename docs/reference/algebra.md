# Reference — General algebra

General-purpose commutative-algebra transforms (`Source/Expr.wl`). Nothing
domain-specific lives here.

## `completeSquare`

```mathematica
completeSquare[x]
```

The scalar transform completing a quadratic in `x`:

\[
a x^2 + b x + c \;\longmapsto\; a\left(x + \tfrac{b}{2a}\right)^2 + \left(c - \tfrac{b^2}{4a}\right).
\]

```mathematica
d = derive[a x^2 + b x + c, Assumptions -> a > 0];
d = step[d, completeSquare[x], "complete the square"];
result[d]   (* c - b^2/(4 a) + a (x + b/(2 a))^2 *)
```

The step is an exact equality, verified symbolically (it is a polynomial
identity in `x`).

!!! info "Matrix version"
    The matrix / exponent form — completing \(x^\top A x + x^\top c + c^\top x\)
    for symmetric \(A\) — is [`completeSquareMat`](matrix.md#completesquaremat),
    in the Matrix module.

!!! note "Native operations"
    For `Expand`, `Factor`, `Collect`, `Apart`, `Together`, `Simplify`, etc., just
    use the Wolfram built-ins directly as transforms — `step[d, Factor]`,
    `step[d, Together]` — and they are verified like any other step. FormalCalc
    only adds the moves the built-ins don't provide cleanly.
