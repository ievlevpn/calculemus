# Examples

Real computations done semi-automatically: a few readable commands, the CAS does
the algebra, every step verified. The runnable scripts are in
[`examples/`](https://github.com/) of the repository; each loads the package and a
small `showChain` printer.

!!! tip "Run one"
    ```bash
    wolframscript -file examples/06_zeta_integral.wl
    ```

## A hard integral in three steps — `∫₀^∞ x³/(eˣ−1) dx`

The Bose–Einstein integral, `= π⁴/15`. You supply the geometric series; the CAS
does the rest, verified symbolically.

```mathematica
compute[ dint[x^3/(E^x - 1), {x, 0, Infinity}], Assumptions -> x > 0 ]
by[ rewrite[1/(E^x - 1) -> sum[E^(-k x), {k, 1, Infinity}]], "geometric series" ]
by[ fubini ]
by[ evaluate ]
result[goal[]]   (* Pi^4/15 *)
```

## Perturbation theory — root of `x = 1 + ε x³`

No closed form. You give the equation and an ansatz; the CAS expands, peels off
the order-by-order equations and solves them; the toolkit verifies the residual
vanishes to `O(ε²)`.

```mathematica
eqn = x - 1 - eps x^3;  ansatz = 1 + a1 eps + a2 eps^2;
expanded  = seriesExpand[eqn /. x -> ansatz, {eps -> 1}, 2];
sol  = First@Solve[Thread[Rest[CoefficientList[expanded, eps]] == 0], {a1, a2}];  (* {a1->1, a2->3} *)
xsol = ansatz /. sol;

d = derive[eqn /. x -> xsol, Grading -> {eps -> 1}, GradingOrder -> 2];
d = step[d, dropHigherOrder[], "residual through O(eps^2)"];
result[d]   (* 0  -- the series solves the equation to this order *)
```

## A generating function — Legendre polynomials

Expand `1/√(1−2xt+t²)` to `O(t³)`; the coefficients *are* the `LegendreP[n,x]`.

```mathematica
d = derive[1/Sqrt[1 - 2 x t + t^2], Grading -> {t -> 1}, GradingOrder -> 3];
d = step[d, dropHigherOrder[], "expand to O(t^3)"];
CoefficientList[result[d], t]   (* {1, x, (3x^2-1)/2, (5x^3-3x)/2} = LegendreP[0..3, x] *)
```

## Integration by parts (CAS finds the antiderivative)

```mathematica
derive[dint[x^2 Exp[x], {x, 0, 1}]] // step[ibp[x^2]]
(* E - Int_0^1 2 x Exp[x]   -- you chose u = x^2; v = e^x computed for you *)
```

## A Gaussian integral by completing the square

```mathematica
derive[Inactive[Integrate][Exp[-(a/2) x^2 + b x], {x, -Infinity, Infinity}], Assumptions -> a > 0]
  // step[gaussianIntegral]
(* Sqrt[2 Pi/a] Exp[b^2/(2 a)] *)
```

## A verified bound chain

`=` then `≥`, with a wrong-direction claim refused.

```mathematica
derive[lead (1 + cross^2), Assumptions -> lead > 0]
  // step[rewrite[lead (1 + cross^2) -> lead + lead cross^2]]   (* = *)
  // step[dropTerm[lead cross^2]]                                (* >= : lower bound *)
(* relationOf -> GreaterEqual, verified;  a boundBy[..., LessEqual] of the same would be Refuted *)
```

## Non-commutative: perturbed inverse `(S − V)⁻¹`

```mathematica
ncDeclareSym[S]; ncDeclare[V];
derive[inv[S - V], Grading -> {V -> 1}, GradingOrder -> 2]
  // step[expandInverse[S, V, 2]]
(* ~ inv[S] + inv[S]**V**inv[S] + inv[S]**V**inv[S]**V**inv[S]
   verified on random SPD S and random V *)
```

## A vanishing quadratic form — `wᵀ(A+Aᵀ)w = 0` when `Aw = 0`

```mathematica
ncDeclare[A]; ncDeclareVec[w];
derive[tp[w] ** (A + tp[A]) ** w, Relations -> {A ** w -> 0, tp[w] ** tp[A] -> 0}]
  // step[NCExpand]
  // step[applyRel[]]
(* = 0, verified by sampling A, w that satisfy A w = 0 *)
```

---

See the [reference](reference/core.md) for every transform, and
[Concepts](concepts/derivations.md) for how the chain and verification work.
