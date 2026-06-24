(* ::Package:: *)

(* ============================================================================
   Example 2 - A quadratic form in the "exponential prefactor" vanishes.

   When expanding the ratio of Gaussian densities (the exponential prefactor),
   one meets terms of the form   w^T (A + A^T) w,   where  w = Sigma^{-1} b  is
   the most-likely-exceedance direction and A satisfies the optimality relation
   A w = 0. Such terms drop out. By hand this is the fiddly "expand, then note
   both pieces vanish by A w = 0" step that is easy to get wrong.

   What you do by hand: declare the relation A w = 0, expand, apply it.
   What the CAS does: applies the relation, and VERIFIES the vanishing by
   sampling random matrices/vectors that actually satisfy A w = 0 (it draws w,
   then builds A annihilating it), then checks the value really is 0.
   ============================================================================ *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "FormalCalc.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "util.wl"}]];

ncDeclare[A];        (* a matrix with the optimality property A w = 0 *)
ncDeclareVec[w];     (* the direction w = Sigma^{-1} b *)

rels = {A ** w -> 0, tp[w] ** tp[A] -> 0};   (* A w = 0 and its transpose *)

(* You guide: carry the relations, symmetrize/expand, then apply the relations *)
d = derive[tp[w] ** (A + tp[A]) ** w, Relations -> rels];
d = step[d, NCExpand,    "expand the symmetric quadratic form"];
d = step[d, applyRel[],  "apply A w = 0  (read from the derivation's relations)"];

showChain["Exponential-prefactor term  w^T (A + A^T) w  with  A w = 0", d];

Print["The term is certified to vanish: random w and random A with A w = 0 make"];
Print["both w^T A w and w^T A^T w numerically zero."];
