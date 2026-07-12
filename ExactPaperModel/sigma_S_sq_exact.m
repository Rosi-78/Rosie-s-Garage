function sigma_S_sq = sigma_S_sq_exact(sigma_i2, corr_matrix)
%SIGMA_S_SQ_EXACT Effective log-normal variance of the EGC sum.
%   算BER的一个中间函数
%   Equation (17) in the paper:
%       sigma_S^2 = sigma_I^2 * (1/M + (1/M^2) * sum_{i~=j} gamma_ij)
%
%   Inputs:
%       sigma_i2    - variance parameter of ln(h) (zeta(0, alpha))
%       corr_matrix - MxM spatial correlation matrix
%   Output:
%       sigma_S_sq  - effective variance of ln(S_EGC)

    M = size(corr_matrix, 1);
    off_diag_sum = sum(corr_matrix(:)) - trace(corr_matrix);
    sigma_S_sq = sigma_i2 * (1 / M + off_diag_sum / M^2);
end
