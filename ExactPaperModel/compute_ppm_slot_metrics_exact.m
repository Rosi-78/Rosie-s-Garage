function metrics = compute_ppm_slot_metrics_exact( ...
    signal_train, background_train, obs_stats, tx_slot, ppm_order, ...
    rate_threshold, grid_size)
%COMPUTE_PPM_SLOT_METRICS_EXACT SER/MI/outage from per-slot scalar statistics.
%
%   Mirrors compute_ppm_slot_metrics.m in EGC_MRC_Analysis.

    all_stats = [signal_train(:); background_train(:); obs_stats(:)];
    low = min(all_stats);
    high = max(all_stats);
    if low == high
        high = low + 1;
    end
    edges = linspace(low, high, grid_size + 1);

    signal_labels = stat_to_labels_exact(signal_train, edges);
    background_labels = stat_to_labels_exact(background_train, edges);
    obs_labels = stat_to_labels_exact(obs_stats, edges);
    num_labels = grid_size;

    signal_counts = accumarray(signal_labels(:), 1, [num_labels, 1]).';
    background_counts = accumarray(background_labels(:), 1, [num_labels, 1]).';
    p_signal = max(signal_counts / max(sum(signal_counts), 1), eps);
    p_background = max(background_counts / max(sum(background_counts), 1), eps);

    num_samples = numel(tx_slot);
    log_likelihood = zeros(ppm_order, num_samples);
    background_log = log(p_background(obs_labels));
    signal_log = log(p_signal(obs_labels));
    background_sum = sum(background_log, 1);

    for candidate = 1:ppm_order
        log_likelihood(candidate, :) = background_sum ...
            - background_log(candidate, :) + signal_log(candidate, :);
    end

    log_norm = max(log_likelihood, [], 1);
    posterior = exp(log_likelihood - log_norm);
    posterior = posterior ./ sum(posterior, 1);
    posterior = max(posterior, eps);
    posterior = posterior ./ sum(posterior, 1);

    local_mi = log2(ppm_order) + sum(posterior .* log2(posterior), 1);
    [~, decision] = max(posterior, [], 1);

    metrics.mi = mean(local_mi);
    metrics.ber = mean(decision ~= tx_slot);
    metrics.posterior_outage = mean(local_mi < rate_threshold);
    metrics.outage = metrics.posterior_outage;
end
