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

## Abbreviations

Name a subexpression, work with the name, restore it later.

```mathematica
abbreviate[w, expr]   (* replace expr by w; record the definition w := expr *)
restore[w]            (* replace w by its recorded definition               *)
restoreAll            (* expand every recorded abbreviation                 *)
definitionsOf[d]      (* the recorded definitions {w -> expr, ...}          *)
```

The definition is recorded on the derivation; **verification transparently
expands it**, so steps stay readable in terms of `w` while the *real* math is what
gets checked.

```mathematica
derive[(p + q)^2 + (p + q)]
  // step[abbreviate[s, p + q], "let s = p + q"]   (* s^2 + s *)
  // step[rewrite[s^2 + s -> s (s + 1)], "factor"] (* s (s + 1) *)
  // step[restore[s]]                              (* (p + q)(p + q + 1) *)
```

Every step here is verified (each holds once `s` is expanded to `p + q`), and a
wrong manipulation under the abbreviation — e.g. claiming `s^2 -> s^3` — is still
`Refuted`.

!!! note "Native operations"
    For `Expand`, `Factor`, `Collect`, `Apart`, `Together`, `Simplify`, etc., just
    use the Wolfram built-ins directly as transforms — `step[d, Factor]`,
    `step[d, Together]` — and they are verified like any other step. Calculemus
    only adds the moves the built-ins don't provide cleanly.
