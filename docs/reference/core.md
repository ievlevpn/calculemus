# Reference — Core

The substrate: the `Derivation` object, relations, verification, and rewrite
helpers. Everything else builds on this.

## Derivations

### `derive`

```mathematica
derive[expr]
derive[expr, Assumptions -> asm, Grading -> g, GradingOrder -> n, Relations -> rels]
```

Start a derivation from `expr`. Options attach **context** read by every step:

| Option | Default | Used by |
|--------|---------|---------|
| `Assumptions` | `True` | scalar verification; may be a boolean or a list |
| `Grading` | `None` | series truncation & `~` verification (e.g. `{e -> 1}`) |
| `GradingOrder` | `None` | the weighted order for `~` checks |
| `Relations` | `{}` | non-commutative side relations (e.g. `{A ** w -> 0}`) |

### `step`

```mathematica
step[d, transform]            step[d, transform, "note"]
step[transform]               step[transform, "note"]     (* curried, for // *)
```

Apply `transform` to `d`, verify the asserted relation, append the step, and
return a new derivation. A transform is `expr -> result` (equality) or
`expr -> Yields[expr, relation, note]`, or `WithContext[(expr, ctx) -> result]`
to read context. See [Performing & verifying](../concepts/performing-and-verifying.md).

### Accessors

```mathematica
result[d]         (* current expression                                   *)
relationOf[d]     (* composed start-to-current relation                   *)
assumptionsOf[d]  (* the assumptions                                      *)
stepsOf[d]        (* list of step records: "result","relation","note","cert" *)
verifiedQ[d]      (* True iff every step Verified or NumericOnly          *)
```

### `Yields`

```mathematica
Yields[expr, relation]        Yields[expr, relation, note]
```

Returned by a transform to assert a non-equality step. A bare expression return
means equality.

## Relations

The relation set is `Equal`, `LessEqual`, `GreaterEqual`, `Less`, `Greater`,
`AsymEqual` (\(\sim\)).

```mathematica
composeRelation[r1, r2]   (* transitive composition; $Failed if incomparable *)
flipRelation[r]           (* reverse direction (LessEqual <-> GreaterEqual)   *)
relationLabel[r]          (* display string ("=", "<=", "~", ...)             *)
```

## Verification

### `certify`

```mathematica
certify[before, after, relation, assumptions]
certify[before, after, relation, assumptions, grading, order, relations]
```

Returns an association with keys `"relation"`, `"symbolic"`, `"numeric"`, and
`"status"` (one of `Verified`, `NumericOnly`, `Unverified`, `Refuted`). You rarely
call this directly — `step` calls it for you — but it is public for custom checks.
Dispatch on the expression kind (scalar / NC / integral / sum) is automatic.

## Rewrite helpers

```mathematica
at[expr, pos, f]    (* apply f at a position (or list of positions)   *)
at[expr, patt, f]   (* apply f at every subexpression matching patt    *)
rewrite[rule]       (* the equality transform  expr |-> (expr /. rule) *)
```

`rewrite` is the everyday equality move:

```mathematica
step[d, rewrite[Sin[x]^2 -> 1 - Cos[x]^2]]
```
