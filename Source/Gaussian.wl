(* ::Package:: *)

(* FormalCalc Gaussian (domain pack, §8): the recurring Gaussian moves, built on
   Matrix (NC quadratic forms, symmetric sampling) and Integral. Loaded in
   FormalCalc`Private`. *)

(* §8.1 log-density exponent of a centered Gaussian (vector x, covariance s),
   NC-aware:  ln phi_s(x)  =  const - 1/2 x^T s^{-1} x. *)
gaussExp[x_, s_] := -1/2 tp[x] ** inv[s] ** x;

(* exponent of a log-density RATIO (the paper's "exponential prefactor" core) *)
prefactorExponent[x1_, s1_, x2_, s2_] := gaussExp[x1, s1] - gaussExp[x2, s2];

(* §8.1 complete the square, scalar:  a x^2 + b x + c. *)
completeSquare[x_] := Function[cur,
  With[{aa = Coefficient[cur, x, 2], bb = Coefficient[cur, x, 1], cc = Coefficient[cur, x, 0]},
    aa (x + bb/(2 aa))^2 + (cc - bb^2/(4 aa))]];

(* §8.1 complete the square, matrix form (A symmetric):
     x^T A x + x^T c + c^T x  =  (x + A^{-1} c)^T A (x + A^{-1} c) - c^T A^{-1} c. *)
gaussQuadForm[A_, c_, x_]       := tp[x] ** A ** x + tp[x] ** c + tp[c] ** x;
gaussCompleteSquare[A_, c_, x_] := With[{y = x + inv[A] ** c}, tp[y] ** A ** y - tp[c] ** inv[A] ** c];

(* §6.8 Gaussian integral normalization:
     Int_{-inf}^{inf} exp(k x^2 + m x + c0) dx = sqrt(-pi/k) exp(c0 - m^2/(4k)),  k < 0. *)
gaussianIntegral := Function[cur,
  cur /. Inactive[Integrate][Exp[q_], {x_, -Infinity, Infinity}] /;
      (PolynomialQ[q, x] && Coefficient[q, x, 2] =!= 0) :>
    With[{k = Coefficient[q, x, 2], m = Coefficient[q, x, 1], c0 = Coefficient[q, x, 0]},
      Sqrt[-Pi/k] Exp[c0 - m^2/(4 k)]]];
