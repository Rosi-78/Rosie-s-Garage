function metrics = compute_binary_stat_metrics_exact( ...
    stat0, stat1, stat_obs, tx, rate_threshold, grid_size)
%COMPUTE_BINARY_STAT_METRICS_EXACT BER/MI/outage for an OOK scalar statistic.
%
%   Mirrors compute_binary_stat_metrics.m in EGC_MRC_Analysis.

    threshold = 0.5 * (mean(stat0) + mean(stat1));
    decision = stat_obs >= threshold;
    [mi, local_mi] = compute_binary_mi_from_stat_exact( ...
        stat0, stat1, stat_obs, grid_size);

    metrics.mi = mi;
    metrics.ber = mean(decision ~= tx);
    metrics.posterior_outage = mean(local_mi < rate_threshold);
    metrics.outage = metrics.posterior_outage;
    metrics.threshold = threshold;
end
