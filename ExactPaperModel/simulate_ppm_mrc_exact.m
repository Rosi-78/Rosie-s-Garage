function metrics = simulate_ppm_mrc_exact(h, lambda_signal, cfg)
%SIMULATE_PPM_MRC_EXACT PPM-MRC using the paper's exact log-normal channel.

    [num_receivers, num_samples] = size(h);
    ppm_order = cfg.ppm_order;
    tx_slot = randi(ppm_order, 1, num_samples);

    p_background = 1 - exp(-cfg.lambda_background / cfg.d_max);
    p_signal = 1 - exp( ...
        -(ppm_order * lambda_signal * h + cfg.lambda_background) / cfg.d_max);
    weights = compute_mrc_count_weights_exact(p_background, p_signal, cfg.d_max);

    counts = generate_ppm_counts_exact(h, tx_slot, p_background, p_signal, cfg);

    background_counts = binomial_rand_exact( ...
        cfg.d_max, p_background * ones(num_receivers, num_samples));
    signal_counts = binomial_rand_exact(cfg.d_max, p_signal);
    background_train = sum(weights .* background_counts, 1);
    signal_train = sum(weights .* signal_counts, 1);

    expanded_weights = reshape( ...
        repmat(reshape(weights, num_receivers, 1, num_samples), ...
        1, ppm_order, 1), num_receivers, []);
    counts_2d = reshape(counts, num_receivers, []);
    obs_stats = reshape(sum(expanded_weights .* counts_2d, 1), ...
        ppm_order, num_samples);

    metrics = compute_ppm_slot_metrics_exact( ...
        signal_train, background_train, obs_stats, tx_slot, ppm_order, ...
        cfg.rate_threshold_ppm, cfg.threshold_grid_size);

    gamma = lambda_signal * sum(h.^2, 1);
    metrics.snr_ber = mean(qfunc_local(sqrt(gamma)));
    metrics = attach_equivalent_snr_metrics_exact( ...
        metrics, gamma, cfg.rate_threshold_ppm);
end
