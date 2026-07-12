function metrics = simulate_ppm_egc_exact(h, lambda_signal, cfg)
%SIMULATE_PPM_EGC_EXACT PPM-EGC using the paper's exact log-normal channel.

    [num_receivers, num_samples] = size(h);
    ppm_order = cfg.ppm_order;
    tx_slot = randi(ppm_order, 1, num_samples);

    p_background = 1 - exp(-cfg.lambda_background / cfg.d_max);
    p_signal = 1 - exp( ...
        -(ppm_order * lambda_signal * h + cfg.lambda_background) / cfg.d_max);

    counts = generate_ppm_counts_exact(h, tx_slot, p_background, p_signal, cfg);

    background_train = sum(binomial_rand_exact( ...
        cfg.d_max, p_background * ones(num_receivers, num_samples)), 1);
    signal_train = sum(binomial_rand_exact(cfg.d_max, p_signal), 1);
    obs_stats = squeeze(sum(counts, 1));

    metrics = compute_ppm_slot_metrics_exact( ...
        signal_train, background_train, obs_stats, tx_slot, ppm_order, ...
        cfg.rate_threshold_ppm, cfg.threshold_grid_size);

    gamma = lambda_signal / num_receivers * sum(h, 1).^2;
    metrics.snr_ber = mean(qfunc_local(sqrt(gamma)));
    metrics = attach_equivalent_snr_metrics_exact( ...
        metrics, gamma, cfg.rate_threshold_ppm);
end
