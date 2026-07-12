function ber = ber_ook_egc_gauss_hermite(lambda_signal, corr_matrix, sigma_i2)
%BER_OOK_EGC_GAUSS_HERMITE Analytical BER for OOK-EGC via Gauss-Hermite.
%
%   Implements equation (20) from the paper. The total EGC irradiance
%   S_EGC is approximated as log-normal with effective variance sigma_S^2
%   given by equation (17).
%
%   Inputs:
%       lambda_signal - mean signal photons per receiver (maps to xi0)
%       corr_matrix   - MxM spatial correlation matrix
%       sigma_i2      - variance parameter of ln(h), i.e. zeta(0, alpha)
%   Output:
%       ber           - average bit-error rate

    M = size(corr_matrix, 1);
    sigma_S_sq = sigma_S_sq_exact(sigma_i2, corr_matrix);
    sigma_S = sqrt(sigma_S_sq);

    xi0 = lambda_signal;

    persistent x_nodes w_weights;
    if isempty(x_nodes)
        [x_nodes, w_weights] = gauss_hermite_nodes(32);
    end

    total = 0.0;
    for k = 1:numel(x_nodes)
        xk = x_nodes(k);
        wk = w_weights(k);

        exp_term = sqrt(2) * sigma_S * xk - sigma_S_sq / 2;
        s_val = exp(exp_term);
        arg_q = sqrt(xi0 / (2 * M)) * s_val;
        total = total + wk * qfunc_local(arg_q);
    end

    ber = total / sqrt(pi);
end
