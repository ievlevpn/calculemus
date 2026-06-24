# Reference — Inequalities

An extensible registry of inequalities applied as directional rewrites
(`Source/Inequalities.wl`). Each carries **side-conditions** that are accumulated
into the derivation's assumptions; an **obvious contradiction** in the
accumulated assumptions is rejected. General inequalities only — domain-specific
ones (Markov, Slepian, …) belong in [packs](../concepts/domain-packs.md).

## Applying a registered inequality

```mathematica
useIneq[name, {args}]   useIneq[name]
```

The transform rewrites the matching subterm, asserts the inequality's relation,
and accumulates its side-conditions. The **overall** direction is still verified
by the core, so a wrong-direction application is `Refuted`.

```mathematica
d = derive[Sqrt[u v]] // step[useIneq["amgm", {u, v}]];
result[d]         (* (u + v)/2 *)
relationOf[d]     (* LessEqual *)
assumptionsOf[d]  (* u >= 0 && v >= 0   <- accumulated from AM-GM *)
verifiedQ[d]      (* True (a true inequality, confirmed under its conditions) *)
```

Conditions from several inequalities accumulate:

```mathematica
derive[Sqrt[u v] + Log[1 + w]]
  // step[useIneq["amgm", {u, v}]]
  // step[useIneq["log-upper", {w}]]
(* assumptions:  u >= 0 && v >= 0 && w > -1 *)
```

### Contradiction rejection

If a new inequality's conditions contradict the assumptions already in force, the
step is rejected:

```mathematica
Quiet @ step[derive[Sqrt[u v], Assumptions -> u < 0], useIneq["amgm", {u, v}]]
(* status: Refuted  --  AM-GM needs u >= 0, but u < 0 is assumed *)
```

## Standard inequalities

| name | relation | statement |
|------|----------|-----------|
| `"triangle"` | `≤` | `\|a + b\| ≤ \|a\| + \|b\|` |
| `"amgm"` | `≤` | `√(a b) ≤ (a + b)/2`,  `a,b ≥ 0` |
| `"young"` | `≤` | `a b ≤ aᵖ/p + b^q/q`,  conjugate `p,q` |
| `"exp-lower"` | `≤` | `1 + x ≤ eˣ` |
| `"log-upper"` | `≤` | `log(1 + x) ≤ x`,  `x > −1` |
| `"bernoulli"` | `≥` | `(1 + x)ʳ ≥ 1 + r x`,  `x ≥ −1, r ≥ 1` |

`inequalities[]` lists the registry (name, relation, description).

## Defining your own

Register a reusable inequality (`applyFn[args]` gives the rewrite rule,
`condFn[args]` the conditions):

```mathematica
registerInequality["my-ineq",
  Function[{a, b}, lhs[a, b] -> rhs[a, b]], LessEqual,
  Function[{a, b}, {a > 0, b > 0}], "Description" -> "..."];
```

`defineInequality[…]` is the same but marks it **taken as given** (status
`Asserted`) — for results you assert without machine proof:

```mathematica
defineInequality["my-bound", Function[{x}, f[x] -> g[x]], LessEqual, Function[{x}, {x > 0}]];
derive[f[t]] // step[useIneq["my-bound", {t}]]
(* status: Asserted (⊢) ; assumptions: t > 0 *)
```

### Ad-hoc assumed bound

For a one-off bound without registering:

```mathematica
assume[lhs -> rhs, relation, conditions]
```

```mathematica
derive[h[s]] // step[assume[h[s] -> k[s], LessEqual, s > 0]]
(* status: Asserted ; conditions accumulated *)
```

!!! note "The `Asserted` status"
    `useIneq`/`assume` for a *taken-as-given* inequality produce the honest
    `Asserted` (⊢) status — recorded with provenance, accepted by `verifiedQ`, but
    not claimed as machine-verified. Standard (true) inequalities instead verify
    normally under their accumulated conditions. This is the same mechanism that
    will host named probabilistic theorems (Slepian / Borell–TIS / Piterbarg) in
    the Gaussian pack.
