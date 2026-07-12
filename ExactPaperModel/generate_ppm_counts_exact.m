function counts = generate_ppm_counts_exact(h, tx_slot, p_background, p_signal, cfg)
%GENERATE_PPM_COUNTS_EXACT Generate receiver/slot photon counts for PPM.
%
%   Mirrors generate_ppm_counts.m in EGC_MRC_Analysis.

    [num_receivers, num_samples] = size(h);
    ppm_order = cfg.ppm_order;
    counts = binomial_rand_exact( ...
        cfg.d_max, p_background * ones(num_receivers, ppm_order, num_samples));

    for slot = 1:ppm_order
        sample_mask = tx_slot == slot;
        if any(sample_mask)
            signal_counts = binomial_rand_exact(cfg.d_max, p_signal(:, sample_mask));
            counts(:, slot, sample_mask) = reshape( ...
                signal_counts, num_receivers, 1, []);
        end
    end
end
