function metrics = simulate_ook_mrc_exact(h, lambda_signal, cfg)
%SIMULATE_OOK_MRC_EXACT OOK-MRC using the paper's exact log-normal channel.
%
%   MRC uses count-domain weights based on branch signal/background separation.
%   There is no closed-form paper BER for MRC, so the error rate is Monte
%   Carlo; only the equivalent-SNR curve is analytical.

    [num_receivers, num_samples] = size(h);
    tx = randi([0, 1], 1, num_samples);

    p0 = 1 - exp(-cfg.lambda_background / cfg.d_max);
    p1 = 1 - exp(-(2 * lambda_signal * h + cfg.lambda_background) / cfg.d_max);
    weights = compute_mrc_count_weights_exact(p0, p1, cfg.d_max);

    p_rx = p0 * ones(num_receivers, num_samples);
    p_rx(:, tx == 1) = p1(:, tx == 1);
    counts = binomial_rand_exact(cfg.d_max, p_rx);

    counts0 = binomial_rand_exact(cfg.d_max, p0 * ones(num_receivers, num_samples));
    counts1 = binomial_rand_exact(cfg.d_max, p1);

    stat_obs = sum(weights .* counts, 1);
    stat0 = sum(weights .* counts0, 1);
    stat1 = sum(weights .* counts1, 1);

    metrics = compute_binary_stat_metrics_exact( ...
        stat0, stat1, stat_obs, tx, ...
        cfg.rate_threshold_ook, cfg.threshold_grid_size);

    gamma = lambda_signal * sum(h.^2, 1);
    metrics.snr_ber = mean(qfunc_local(sqrt(gamma)));
    metrics = attach_equivalent_snr_metrics_exact(metrics, gamma, cfg.rate_threshold_ook);
end
