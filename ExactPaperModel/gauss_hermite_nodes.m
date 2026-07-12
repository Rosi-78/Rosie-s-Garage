function [x, w] = gauss_hermite_nodes(n)
%GAUSS_HERMITE_NODES Nodes and weights for Gauss-Hermite quadrature.
%
%   Computes the n-point Gauss-Hermite rule for integrals of the form
%       integral_{-inf}^{+inf} exp(-x^2) f(x) dx
%
%   Uses the symmetric tridiagonal Jacobi matrix for physicists' Hermite
%   polynomials (Golub-Welsch algorithm).
%
%   Inputs:
%       n - number of quadrature points (default 32)
%   Outputs:
%       x - nodes (column vector)
%       w - weights (column vector)

    if nargin < 1
        n = 32;
    end

    % Off-diagonal entries of the Jacobi matrix: sqrt(k/2), k=1..n-1
    off_diag = sqrt((1:n-1) / 2);
    J = diag(off_diag, 1) + diag(off_diag, -1);

    [V, D] = eig(J);
    x = diag(D);
    w = sqrt(pi) * V(1, :).^2;

    % Sort by node value for cleanliness
    [x, order] = sort(x);
    w = w(order).';
end
