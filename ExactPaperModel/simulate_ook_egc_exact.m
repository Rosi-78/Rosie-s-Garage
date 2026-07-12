function metrics = simulate_ook_egc_exact(h, lambda_signal, cfg, corr_matrix, sigma_i2)
%SIMULATE_OOK_EGC_EXACT OOK-EGC using the paper's exact log-normal channel.
%
%   Inputs:
%       h           - MxN channel gain matrix (from generate_correlated_lognormal)
%       lambda_signal - mean signal photons per receiver
%       cfg         - configuration struct
%       corr_matrix - MxM spatial correlation matrix (required for GH BER)
%       sigma_i2    - variance parameter of ln(h) (required for GH BER)
%   Output:
%       metrics     - struct with mi, ber, outage, snr_ber, snr_capacity

    [num_receivers, num_samples] = size(h);
    tx = randi([0, 1], 1, num_samples);

    p0 = 1 - exp(-cfg.lambda_background / cfg.d_max);
    p1 = 1 - exp(-(2 * lambda_signal * h + cfg.lambda_background) / cfg.d_max);

    p_rx = p0 * ones(num_receivers, num_samples);
    p_rx(:, tx == 1) = p1(:, tx == 1);
    counts = binomial_rand_exact(cfg.d_max, p_rx);

    counts0 = binomial_rand_exact(cfg.d_max, p0 * ones(num_receivers, num_samples));
    counts1 = binomial_rand_exact(cfg.d_max, p1);

    stat_obs = sum(counts, 1);
    stat0 = sum(counts0, 1);
    stat1 = sum(counts1, 1);

    metrics = compute_binary_stat_metrics_exact( ...
        stat0, stat1, stat_obs, tx, ...
        cfg.rate_threshold_ook, cfg.threshold_grid_size);

    % Equivalent SNR and paper-consistent Gauss-Hermite BER
    gamma = lambda_signal / num_receivers * sum(h, 1).^2;
    metrics.snr_ber = ber_ook_egc_gauss_hermite(lambda_signal, corr_matrix, sigma_i2);
    metrics = attach_equivalent_snr_metrics_exact(metrics, gamma, cfg.rate_threshold_ook);
end
