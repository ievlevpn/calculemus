(* ::Package:: *)

(* ============================================================================
   Example 5 - A verified chain of bounds (the heart of asymptotic analysis).

   Asymptotic estimates are chains of equalities and inequalities on one
   quantity, and the dangerous part by hand is the DIRECTION bookkeeping. Here
   the running relation (=, then >=) is composed automatically, and every step
   is checked: an equality must hold identically, and a ">=" step must really be
   a lower bound (a dropped term must really be nonnegative).

   This mirrors the paper's "Xi >= 2 sum w^T A_2 w" move: an exact expansion,
   then drop a nonnegative remainder to get a lower bound.
   ============================================================================ *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "FormalCalc.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "util.wl"}]];

(* You guide: expand the generalized variance, then drop the >=0 cross term. *)
d = derive[lead (1 + cross^2), Assumptions -> lead > 0];
d = step[d, rewrite[lead (1 + cross^2) -> lead + lead cross^2],
     "expand  (=)"];
d = step[d, dropTerm[lead cross^2],
     "drop the nonnegative remainder lead*cross^2  =>  lower bound  (>=)"];

showChain["Lower bound:  lead (1 + cross^2)  >=  lead", d];

(* And the guard that makes it trustworthy: a WRONG-direction claim is refused. *)
Print["What if we claimed an UPPER bound by the same drop? The verifier refuses:"];
bad = Quiet@step[derive[lead + lead cross^2, Assumptions -> lead > 0],
   boundBy[lead, LessEqual]];           (* claims lead + lead cross^2 <= lead : false *)
Print["  claimed  (lead + lead cross^2) <= lead   ->   status: ",
      stepsOf[bad][[1]]["cert"]["status"], "  (correctly rejected)"];
