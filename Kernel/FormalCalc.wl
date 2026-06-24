(* ::Package:: *)

(* FormalCalc — verifiable step-by-step formal manipulation.
   Master loader: declares the public API, then loads the implementation
   files into the private context. See notes/architecture.md. *)

(* NCAlgebra backend for non-commutative algebra (tp/aj/inv/** used directly).
   Pre-loaded here so the contexts are on the path for the Matrix module and the
   user. Pre-setting NCAlgebra's private $NCAlgebra$Loaded flag makes its loader
   non-verbose, suppressing the banner (a FilePrint, not catchable via Print);
   Quiet suppresses the "small caps are non-commutative" message. Required §3. *)
NCAlgebra`Private`$NCAlgebra$Loaded = True;
Quiet@Needs["NCAlgebra`"];

BeginPackage["FormalCalc`", {"NonCommutativeMultiply`", "NCReplace`"}];

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

(* ---- Subexpression addressing (§0.1) ---- *)
on::usage        = "on[where, op] applies transform op to the subexpression(s) at locator `where` (verified). E.g. on[integrand, expand], on[argOf[Exp], completeSquare[x]], on[term[2], factor], on[_^2, op].";
partOf::usage    = "partOf[expr, where] returns the subexpression(s) addressed by locator `where` (to confirm what you are pointing at).";
highlight::usage = "highlight[expr, where] displays expr with the addressed subexpression(s) boxed.";
integrand::usage = "integrand: locator for the body of a held integral.";
summand::usage   = "summand: locator for the body of a held sum.";
argOf::usage     = "argOf[h]: locator for the argument of h. argOf[Exp] is the exponent of e^x, argOf[Sqrt] the radicand, argOf[Log] inside the log, etc.";
term::usage      = "term[n]: locator for the n-th additive term (firstTerm, lastTerm also).";
factor::usage    = "factor[n]: locator for the n-th multiplicative factor.";
firstTerm::usage = "firstTerm / lastTerm: locators for the first / last additive term.";
lastTerm::usage  = "lastTerm: locator for the last additive term.";
numerator::usage = "numerator / denominator: locators for the numerator / denominator.";
denominator::usage = "denominator: locator for the denominator.";

(* ---- General expression algebra (Layer 1, §1-§2) ---- *)
completeSquare::usage = "completeSquare[x] is the scalar transform completing a x^2 + b x + c into a (x + b/(2a))^2 + (c - b^2/(4a)).";
abbreviate::usage     = "abbreviate[w, expr] is the transform naming a subexpression: it replaces expr by w and records the definition w := expr (expanded transparently during verification).";
restore::usage        = "restore[w] replaces the abbreviation w by its recorded definition; restoreAll expands every abbreviation.";
restoreAll::usage     = "restoreAll is the transform expanding every recorded abbreviation back to its definition.";
definitionsOf::usage  = "definitionsOf[d] returns the abbreviation definitions (w -> expr) recorded on derivation d.";

(* ---- Series & graded asymptotics (Layer 1, §4) ---- *)
Grading::usage        = "Grading is a derive option: a list {g -> w, ...} (or {g, ...} for weight 1) assigning small generators their weights. Enables verification of ~ steps.";
GradingOrder::usage   = "GradingOrder is a derive option: the weighted order up to which ~ steps must agree.";
truncate::usage       = "truncate[expr, grading, order] keeps the monomials of expr whose weighted degree is <= order (expr must be polynomial in the generators). truncate[expr, grading, order, asm] uses assumptions to decide symbolic comparisons.";
seriesExpand::usage   = "seriesExpand[expr, grading, order] expands expr to weighted order in the graded generators (reciprocals, exp, log, ...), via eps-homogenization. Rational weights + numeric order required for full expansion; otherwise falls back to polynomial truncation.";
dropHigherOrder::usage = "dropHigherOrder[grading, order] is the transform that expands and drops terms above the weighted order, asserting a ~ (AsymEqual) step. Auto-verified when the derivation carries a matching Grading/GradingOrder.";
monomialWeight::usage = "monomialWeight[monomial, grading] is the weighted degree of a single monomial.";
normalizeGrading::usage = "normalizeGrading[g] canonicalizes a grading spec to a list of generator -> weight rules.";
littleO::usage        = "littleO[scale] marks an omitted term of order o(scale). Idempotent under addition; absorbs nonzero numeric factors.";
bigO::usage           = "bigO[scale] marks an omitted term of order O(scale). Idempotent under addition; absorbs littleO[scale] and nonzero numeric factors.";

(* ---- Non-commutative / matrix algebra (Layer 1, §3 + §4.6) ---- *)
ncDeclare::usage      = "ncDeclare[a, b, ...] marks symbols as non-commutative matrices/operators for both NCAlgebra and FormalCalc's verification. Multi-letter symbols must be declared; NCAlgebra treats single lowercase letters as non-commutative already.";
ncDeclareVec::usage   = "ncDeclareVec[v, ...] marks symbols as (column) vectors, so random-matrix verification gives them shape dim x 1 (and tp[v] shape 1 x dim).";
neumannInverse::usage = "neumannInverse[s, e, n] is the order-n Neumann truncation of inv[s - e] = Sum_{k=0}^n (inv[s]**e)^k ** inv[s], treating e as the small (weight-1) generator.";
expandInverse::usage  = "expandInverse[s, e, n] is the transform replacing inv[s-e] by its order-n Neumann truncation, asserting a ~ step (auto-verified via random-matrix order probe when the derivation carries Grading -> {e -> 1}, GradingOrder -> n).";
ncDeclareSym::usage   = "ncDeclareSym[A, ...] marks symbols as symmetric matrices, sampled as symmetric positive-definite in verification (e.g. covariances).";
symPart::usage        = "symPart[a] = (a + tp[a])/2, the symmetric part.";
antiPart::usage       = "antiPart[a] = (a - tp[a])/2, the antisymmetric part.";
quadForm::usage          = "quadForm[A, c, x] = tp[x]**A**x + tp[x]**c + tp[c]**x, a symmetric quadratic form with linear term.";
completeSquareMat::usage = "completeSquareMat[A, c, x] = (x + A^-1 c)^T A (x + A^-1 c) - c^T A^-1 c, the completed square of quadForm[A,c,x] for symmetric A.";
applyRel::usage       = "applyRel[rules] is the transform that applies NC side-relations (e.g. {A ** w -> 0}) via NCReplaceAll. Verified by random matrices/vectors that satisfy the derivation's Relations.";
Relations::usage      = "Relations is a derive option: a list of NC side relations of the form {mat ** vec -> 0, ...}. Verification samples random matrices/vectors satisfying them.";

(* ---- Formal integrals (Layer 1, §6) ---- *)
dint::usage      = "dint[f, {x, a, b}] is the held definite integral Inactive[Integrate][f, {x, a, b}].";
iint::usage      = "iint[f, x] is the held indefinite integral Inactive[Integrate][f, x].";
linearity::usage = "linearity is the transform that splits held integrals over sums and pulls out factors free of the integration variable.";
changeVar::usage = "changeVar[u, phi, {ua, ub}] is the transform substituting the (single) integration variable x = phi (in u), inserting the Jacobian D[phi, u] and new limits {ua, ub}.";
ibp::usage       = "ibp[u, v] is the integration-by-parts transform: the integrand must equal u * D[v, x]; yields the boundary term u v | minus the held remainder integral of D[u,x] v.";
splitDomain::usage = "splitDomain[c] splits a held definite integral at the interior point c.";
swapSumIntegral::usage = "swapSumIntegral interchanges a held Inactive[Sum] and Inactive[Integrate] (either order).";
gaussianIntegral::usage = "gaussianIntegral is the transform normalizing Int_{-inf}^{inf} Exp[quadratic in x] dx to its closed form (a general definite-integral identity).";

(* ---- Formal sums (Layer 1, §5) ---- *)
sum::usage          = "sum[f, {k, a, b}] is the held sum Inactive[Sum][f, {k, a, b}].";
sumLinearity::usage = "sumLinearity is the transform that splits held sums over addends and pulls out factors free of the index.";
shiftIndex::usage   = "shiftIndex[c] reindexes a held sum k -> k-c, shifting the bounds by c.";
splitSum::usage     = "splitSum[m] splits a held sum's range at the interior point m.";
swapSum::usage      = "swapSum interchanges the order of two nested held sums (Fubini), assuming independent bounds.";

(* ---- Bounds (Layer 1, §9) ---- *)
signOf::usage   = "signOf[expr] or signOf[expr, assumptions] returns Positive, Negative, NonNegative, NonPositive, or Unknown.";
dropTerm::usage = "dropTerm[term] is the transform that drops a nonnegative term, asserting a GreaterEqual step (current >= current - term).";
boundBy::usage  = "boundBy[newExpr] (or boundBy[newExpr, relation]) is the transform that replaces the current expression by newExpr, asserting the given relation (default LessEqual). The verifier checks the claim.";
boundSub::usage = "boundSub[rule] (or boundSub[rule, relation]) bounds a subterm via rule, asserting the given relation (default LessEqual) for the whole expression.";

(* ---- Standard & user-defined inequalities (Layer 1, §9.5) ---- *)
registerInequality::usage = "registerInequality[name, applyFn, relation, condFn, opts] registers an inequality: applyFn[args] gives the rewrite rule, condFn[args] the side-conditions. Option \"Assumed\"->True marks it taken-as-given (status Asserted).";
defineInequality::usage   = "defineInequality[name, applyFn, relation, condFn] registers a USER inequality taken as given (status Asserted), with side-conditions accumulated.";
useIneq::usage            = "useIneq[name, {args}] is the transform applying the registered inequality `name` to `args`: it rewrites the subterm, asserts the relation, and accumulates the side-conditions into the derivation's assumptions.";
assume::usage             = "assume[lhs -> rhs, relation, conditions] applies an ad-hoc bound taken as given (status Asserted), accumulating conditions. Inline alternative to registering.";
inequalities::usage       = "inequalities[] lists the registered inequalities (name, relation, description).";

(* ---- Two-sided (in)equations (Layer 1/2, §9.2) ---- *)
TwoSided::usage    = "TwoSided[<|...|>] is an immutable two-sided (in)equation value. Build with relate; advance with stepBoth.";
relate::usage      = "relate[L, R, M] (or relate[L <= M], etc.) starts a two-sided (in)equation L R M. Apply the same operation to both sides with stepBoth.";
stepBoth::usage    = "stepBoth[obj, op] (or curried stepBoth[op]) applies operation op to BOTH sides of a two-sided relation, verifying the new relation follows from the old. Ops: addBoth, subtractBoth, mulBoth, applyBoth, rewriteBoth.";
addBoth::usage     = "addBoth[c] adds c to both sides.";
subtractBoth::usage = "subtractBoth[c] subtracts c from both sides.";
mulBoth::usage     = "mulBoth[c] multiplies both sides by c, flipping the relation when c is (provably) negative.";
applyBoth::usage   = "applyBoth[f] applies f to both sides (preserving the relation; assumes f increasing, verified). applyBoth[f, \"Decreasing\"] flips the relation.";
rewriteBoth::usage = "rewriteBoth[rule] rewrites both sides via rule (relation unchanged).";
lhsOf::usage       = "lhsOf[obj] / rhsOf[obj] return the current left/right sides of a two-sided relation.";
rhsOf::usage       = "rhsOf[obj] returns the current right side of a two-sided relation.";

(* ---- Natural surface syntax (tactic mode + verbs) ---- *)
compute::usage = "compute[expr] starts an interactive derivation (a 'page'); compute[L <= M] (any relation) starts a two-sided one. Continue with by[...], step back with undo[], inspect with goal[].";
by::usage      = "by[op] adds a verified line to the current computation by applying op (e.g. by[ibp[x]], by[amgm[a,b]], by[fubini]); by[op, \"note\"] adds a margin note.";
undo::usage    = "undo[] steps the current computation back one line.";
goal::usage    = "goal[] is the current state of the interactive computation.";
atMost::usage  = "atMost[x] asserts the current quantity is <= x (verified). atLeast[x] asserts >= x.";
atLeast::usage = "atLeast[x] asserts the current quantity is >= x (verified).";
drop::usage    = "drop[t] drops the nonnegative term t (a >= step). Alias of dropTerm.";
let::usage     = "let[w, expr] names a subexpression: w := expr. Alias of abbreviate.";
evaluate::usage = "evaluate activates held integrals/sums to evaluate them. Alias of Activate.";
fubini::usage  = "fubini interchanges the order of a sum and an integral (or two nested sums).";
amgm::usage    = "amgm[a, b] applies the AM-GM inequality Sqrt[a b] <= (a+b)/2.";
triangleIneq::usage = "triangleIneq[a, b] applies the triangle inequality |a+b| <= |a|+|b|.";
young::usage   = "young[a, b, p, q] applies Young's inequality a b <= a^p/p + b^q/q.";
bernoulli::usage = "bernoulli[x, r] applies Bernoulli's inequality (1+x)^r >= 1 + r x.";
expBound::usage = "expBound[x] applies 1 + x <= e^x.";
logBound::usage = "logBound[x] applies log(1 + x) <= x.";

Begin["`Private`"];

$dir = DirectoryName[$InputFileName];
Get[FileNameJoin[{$dir, "..", "Source", "Core.wl"}]];
Get[FileNameJoin[{$dir, "..", "Source", "Expr.wl"}]];
Get[FileNameJoin[{$dir, "..", "Source", "Subexpr.wl"}]];
Get[FileNameJoin[{$dir, "..", "Source", "Series.wl"}]];
Get[FileNameJoin[{$dir, "..", "Source", "Matrix.wl"}]];
Get[FileNameJoin[{$dir, "..", "Source", "Integral.wl"}]];
Get[FileNameJoin[{$dir, "..", "Source", "Sums.wl"}]];
Get[FileNameJoin[{$dir, "..", "Source", "Bounds.wl"}]];
Get[FileNameJoin[{$dir, "..", "Source", "Inequalities.wl"}]];
Get[FileNameJoin[{$dir, "..", "Source", "TwoSided.wl"}]];
Get[FileNameJoin[{$dir, "..", "Source", "Syntax.wl"}]];

End[];

EndPackage[];
