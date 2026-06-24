(* ::Package:: *)

(* FormalCalc — verifiable step-by-step formal manipulation.
   Master loader: declares the public API, then loads the implementation
   files into the private context. See notes/architecture.md. *)

BeginPackage["FormalCalc`"];

(* ---- Derivation: the relation-chain object (Layer 2) ---- *)
derive::usage        = "derive[expr] starts a derivation from expr. derive[expr, Assumptions -> asm] attaches assumptions used to verify every step.";
step::usage          = "step[d, f] applies transform f to derivation d, verifies the asserted relation, and returns the new derivation. step[d, f, note] adds a note. Curried: step[f] and step[f, note] return a function of d, for use with //.";
result::usage        = "result[d] is the current (last) expression of derivation d.";
relationOf::usage    = "relationOf[d] is the relation between the start and the current expression of d (transitive composition of all step relations).";
assumptionsOf::usage = "assumptionsOf[d] returns the assumptions of derivation d.";
stepsOf::usage       = "stepsOf[d] returns the list of step records of d.";
verifiedQ::usage     = "verifiedQ[d] is True iff every step of d verified (status Verified or NumericOnly).";
Derivation::usage    = "Derivation[<|...|>] is an immutable derivation value. Build with derive/step; inspect with the accessors.";
Yields::usage        = "Yields[expr, relation] (or Yields[expr, relation, note]) is returned by a transform to assert that it changes the relation to the given one. A transform that returns a bare expression asserts equality.";

(* ---- Relations algebra ---- *)
composeRelation::usage = "composeRelation[r1, r2] transitively composes two relations (e.g. LessEqual,LessEqual -> LessEqual). Incomparable relations give $Failed.";
flipRelation::usage    = "flipRelation[r] reverses a relation's direction (LessEqual <-> GreaterEqual), as when multiplying by a negative quantity.";
relationLabel::usage   = "relationLabel[r] is the display string for a relation.";
AsymEqual::usage       = "AsymEqual is the relation head for asymptotic equivalence (~).";

(* ---- Verification (Layer 0, §0.4) ---- *)
certify::usage = "certify[before, after, relation, assumptions] checks whether 'before relation after' holds, symbolically and numerically, returning an association with key \"status\" in {Verified, NumericOnly, Unverified, Refuted}.";

(* ---- Rewrite helpers (§0.1) ---- *)
at::usage      = "at[expr, pos, f] applies f to the subexpression(s) at position pos. at[expr, patt, f] applies f to every subexpression matching pattern patt.";
rewrite::usage = "rewrite[rule] is the equality transform expr |-> (expr /. rule).";

(* ---- Bounds (Layer 1, §9) ---- *)
signOf::usage   = "signOf[expr] or signOf[expr, assumptions] returns Positive, Negative, NonNegative, NonPositive, or Unknown.";
dropTerm::usage = "dropTerm[term] is the transform that drops a nonnegative term, asserting a GreaterEqual step (current >= current - term).";
boundBy::usage  = "boundBy[newExpr] (or boundBy[newExpr, relation]) is the transform that replaces the current expression by newExpr, asserting the given relation (default LessEqual). The verifier checks the claim.";
boundSub::usage = "boundSub[rule] (or boundSub[rule, relation]) bounds a subterm via rule, asserting the given relation (default LessEqual) for the whole expression.";

Begin["`Private`"];

$dir = DirectoryName[$InputFileName];
Get[FileNameJoin[{$dir, "..", "Source", "Core.wl"}]];
Get[FileNameJoin[{$dir, "..", "Source", "Bounds.wl"}]];

End[];

EndPackage[];
