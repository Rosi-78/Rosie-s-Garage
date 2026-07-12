function weights = compute_mrc_count_weights_exact(p_background, p_signal, d_max)
%COMPUTE_MRC_COUNT_WEIGHTS_EXACT Photon-counting MRC-style branch weights.
%
%   Mirrors compute_mrc_count_weights.m in EGC_MRC_Analysis.
%
%   For Binomial(D, p):
%       E[N] = D*p, Var[N] = D*p*(1-p)
%   Weight proportional to (mean_signal - mean_background) / avg_variance.

    mean_background = d_max * p_background;
    mean_signal = d_max * p_signal;
    delta_mean = mean_signal - mean_background;

    var_background = d_max * p_background .* (1 - p_background);
    var_signal = d_max * p_signal .* (1 - p_signal);
    avg_variance = 0.5 * (var_background + var_signal);

    weights = delta_mean ./ max(avg_variance, eps);
    weights = weights ./ max(sqrt(sum(weights.^2, 1)), eps);
end
